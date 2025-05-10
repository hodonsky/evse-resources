// CALL apoc.trigger.add(
//   'validateUserProps',
//   '
//   UNWIND $createdNodes AS n
//   WITH n WHERE n:User
//   WITH n, [k IN keys(n) WHERE NOT k IN ["name","email","createdAt","updatedAt"]] AS forbidden
//   CALL apoc.util.validate(
//     size(forbidden)>0,
//     "Disallowed properties on User: "+forbidden,
//     []
//   )
//   RETURN n
//   ',
//   {phase:'before'}
// );
// CREATE CONSTRAINT requireName IF NOT EXISTS
// FOR (u:User)
// REQUIRE u.id IS NOT NULL;
// CREATE CONSTRAINT uniqueUserEmail IF NOT EXISTS
// FOR (u:User)
// REQUIRE (u.id) IS NODE KEY;

// Check for empty graph
MATCH (n)
WITH COUNT(n) AS nodeCount
WHERE nodeCount = 0
WITH nodeCount

// Load organizations
LOAD CSV WITH HEADERS FROM 'file:///organizations.csv' AS row
MERGE (org:Organization {id: row.id})
ON CREATE SET org.name = row.name;

// Load subsidiary relationships
LOAD CSV WITH HEADERS FROM 'file:///subsidiaryMap.csv' AS row1
MATCH (parent:Organization {id: row1.parentOrganizationId})
MATCH (subsidiary:Organization {id: row1.subsidiaryOrganizationId})
WITH parent, subsidiary, row1
WHERE parent IS NOT NULL AND subsidiary IS NOT NULL
MERGE (parent)-[r:HAS_SUBSIDIARY]->(subsidiary)
ON CREATE SET r.ownershipPercentage = row1.ownershipPercentage,
              r.since = row1.since,
              r.source = row1.source,
              r.status = row1.status,
              r.type = row1.type;

// Load sites and assign stewards
LOAD CSV WITH HEADERS FROM 'file:///sites.csv' AS row2
MATCH (org:Organization {id: row2.organizationId})
MERGE (site:Site {id: row2.id})
ON CREATE SET site.name = row2.name
MERGE (org)-[r:STEWARDS]->(site)
ON CREATE SET r.role = row2.role,
              r.tenure = row2.tenure,
              r.since = date(row2.since),
              r.until = CASE WHEN row2.until IS NOT NULL THEN date(row2.until) ELSE NULL END,
              r.delegatedFinancials = toBoolean(row2.delegatedFinancials),
              r.status = row2.status,
              r.source = row2.source,
              r.notes = row2.notes;

// Load EVSE Groups and their site relationships
LOAD CSV WITH HEADERS FROM 'file:///evseGroups.csv' AS row3
MATCH (site:Site {id: row3.siteId})
MERGE (group:EVSEGroup {id: row3.id})
ON CREATE SET group.name = row3.name,
              group.created = datetime(row3.created),
              group.status = row3.status,
              group.notes = row3.notes
MERGE (site)-[:MANAGES_GROUP]->(group);

// Load EVSE Vendors
LOAD CSV WITH HEADERS FROM 'file:///evseVendors.csv' AS row4
MERGE (vendor:EVSEVendor {id: row4.id})
ON CREATE SET vendor.name = row4.vendorName,
              vendor.country = row4.vendorCountry,
              vendor.certified = toBoolean(row4.vendorCertified),
              vendor.ocppVersions = split(row4.vendorOcppVersions, ";"),
              vendor.contactEmail = row4.vendorEmail;

// Load EVSE Models
LOAD CSV WITH HEADERS FROM 'file:///evseModels.csv' AS row5
MERGE (model:EVSEModel {id: row5.id})
ON CREATE SET model.name = row5.modelName,
              model.maxPowerKw = toFloat(row5.maxPowerKw),
              model.connectorTypes = split(row5.connectorTypes, ";"),
              model.ocppVersion = row5.modelOcppVersion,
              model.phase = row5.phase,
              model.availablePorts = toInteger(row5.portCount),
              model.active = toBoolean(row5.modelActive);

// Load EVSEs and their model/vendor/org relationships
LOAD CSV WITH HEADERS FROM 'file:///evses.csv' AS row6
MATCH (vendor:EVSEVendor {id: row6.vendorId})
MATCH (model:EVSEModel {id: row6.modelId})
MATCH (org:Organization {id: row6.organizationId})
MATCH (fw:Firmware {id: row6.firmwareId})
MERGE (evse:EVSE {id: row6.id})
ON CREATE SET evse.created = datetime(row6.created),
              evse.virtual = toBoolean(row6.virtual),
              evse.test = toBoolean(row6.test),
              evse.publicKey = row6.publicKey,
              evse.lastSeen = datetime(row6.lastSeen),
              evse.timezone = row6.timezone
MERGE (evse)-[:IS_MODEL]->(model)
MERGE (evse)-[:BELONGS_TO]->(org)
MERGE (evse)-[:SOLD_BY]->(vendor)
MERGE (evse)-[:CONFIGURED_WITH]->(fw);


// Load EVSEGroup → EVSE relationships
LOAD CSV WITH HEADERS FROM 'file:///evseGroupRelationships.csv' AS row7
MATCH (group:EVSEGroup {id: row7.groupId})
MATCH (evse:EVSE {id: row7.evseId})
MERGE (group)-[r:INCLUDES]->(evse)
ON CREATE SET r.added = row7.added,
              r.active = row7.active,
              r.priority = row7.priority,
              r.notes = row7.notes;

// Load Connector Types
LOAD CSV WITH HEADERS FROM 'file:///connectorTypes.csv' AS row8
MERGE (type:ConnectorType {id: row8.id})
ON CREATE SET type.name = row8.name,
              type.description = row8.description,
              type.maxPowerKw = toFloat(row8.maxPowerKw),
              type.standard = row8.standard;

// Load Connectors and relationships to EVSEs
LOAD CSV WITH HEADERS FROM 'file:///connectors.csv' AS row9
MATCH (evse:EVSE {id: row9.evseId})
MATCH (type:ConnectorType {id: row9.typeId})
MERGE (connector:Connector {id: row9.id})
ON CREATE SET connector.available = row9.available,
              connector.maxCurrentA = row9.maxCurrentA,
              connector.maxPowerKw = row9.maxPowerKw,
              connector.voltageV = row9.voltageV,
              connector.phase = row9.phase,
              connector.notes = row9.notes
MERGE (connector)-[rct:IS_TYPE]->(type)
ON CREATE SET rct.source = "FACTORY_CERT"
MERGE (evse)-[rec:HAS_CONNECTOR]->(connector)
ON CREATE SET rec.added = row9.added,
              rec.position = row9.connectorId;

// Load EVSEModel ↔ ConnectorType support
LOAD CSV WITH HEADERS FROM 'file:///modelConnectorRelationships.csv' AS row10
MERGE (model:EVSEModel {id: row10.modelId})
MERGE (type:ConnectorType {id: row10.connectorTypeId})
MERGE (model)-[:SUPPORTS]->(type);

// Load Firmware
LOAD CSV WITH HEADERS FROM 'file:///firmware.csv' AS row11
MERGE (firmware:Firmware {id: row11.firmwareId})
ON CREATE SET firmware.name = row11.name,
              firmware.version = row11.version,
              firmware.releaseDate = datetime(row11.releaseDate);

// Load Model ↔ Vendor relationships
LOAD CSV WITH HEADERS FROM 'file:///modelManufacturerRelationships.csv' AS row12
MERGE (model:EVSEModel {id: row12.modelId})
MERGE (manufacturer:Manufacturer {id: row12.manufacturerId})
MERGE (model)-[r:MADE_BY]->(manufacturer)
ON CREATE SET r.source = row12.source;

// Load EVSE ↔ Model relationships
LOAD CSV WITH HEADERS FROM 'file:///evseModelRelationships.csv' AS row13
MATCH (evse:EVSE {id: row13.evseId})
MATCH (model:EVSEModel {id: row13.modelId})
MERGE (evse)-[r:IS_MODEL]->(model)
ON CREATE SET r.from = datetime(row13.from),
              r.to = CASE WHEN row13.to IS NOT NULL THEN datetime(row13.to) ELSE NULL END,
              r.firmwareCompatible = toBoolean(row13.firmwareCompatible);

// Load EVSE ↔ Firmware relationships
LOAD CSV WITH HEADERS FROM 'file:///evseFirmwareRelationships.csv' AS row14
MATCH (evse:EVSE {id: row14.evseId})
MATCH (firmware:Firmware {id: row14.firmwareId})
MERGE (evse)-[r:CONFIGURED_WITH]->(firmware)
ON CREATE SET r.from = row14.from,
              r.to = CASE WHEN row14.to IS NOT NULL THEN datetime(row14.to) ELSE NULL END;

// Station Mounts
LOAD CSV WITH HEADERS FROM 'file:///stationMounts.csv' AS row60
MATCH (stationModel:StationModel {id: row60.station_id})
MERGE (mount:StationMount {id: row60.mount_id})
ON CREATE SET mount.type = row60.mount_type,
              mount.material = row60.material,
              mount.installed_on = datetime(row60.installed_on)
WITH stationModel, mount, row60  
MERGE (stationModel)-[r:USES_MOUNT]->(mount);

LOAD CSV WITH HEADERS FROM 'file:///stationModels.csv' AS row14a
MATCH (stationMount:StationMount {id: row14a.station_model_mount_id})
MERGE (stationModel:StationModel {id: row14a.station_model_id})
ON CREATE SET stationModel = {
                id: row14a.station_model_id,
                name: row14a.station_model_name,
                description: row14a.station_model_description,
                capacity: row14a.station_model_capacity,
                recoilers: row14a.station_model_recoilers,
                orientation: row14a.station_model_orientation,
                active: toBoolean(true)
}
MERGE (stationModel)-[r:SUPPORTS_MOUNT]->(stationMount);

// Load enriched Station nodes
LOAD CSV WITH HEADERS FROM 'file:///stations.csv' AS row15
MATCH (stationModel:StationModel { id: row15.station_model_id })
MERGE (station:Station {id: row15.station_id})
ON CREATE SET station.name = row15.name,
              station.location = point({latitude: toFloat(row15.latitude), longitude: toFloat(row15.longitude)}),
              station.address = row15.address,
              station.created = datetime(row15.created),
              station.orientation = row15.orientation,
              station.mount_type = row15.mount_type,
              station.weather_rating = row15.weather_rating,
              station.capacity = toInteger(row15.capacity),
              station.recoilers = toBoolean(row15.recoilers)
MERGE (station)-[:IS_MODEL]->(stationModel);

// Load Manufacturer nodes
LOAD CSV WITH HEADERS FROM 'file:///manufacturers.csv' AS row16
MERGE (manufacturer:Manufacturer {id: row16.manufacturer_id})
ON CREATE SET manufacturer.name = row16.name,
              manufacturer.country = row16.country,
              manufacturer.certifications = split(row16.certifications, ";");

// Station → Manufacturer (MADE_BY)
LOAD CSV WITH HEADERS FROM 'file:///stationManufacturerRelationships.csv' AS row17
MERGE (station:Station {id: row17.station_id})
MERGE (manufacturer:Manufacturer {id: row17.manufacturer_id})
MERGE (station)-[r:MADE_BY]->(manufacturer)
ON CREATE SET r.made_on = datetime(row17.made_on);

// Station → Subpanel (CONNECTED_TO)
LOAD CSV WITH HEADERS FROM 'file:///stationSubpanelRelationships.csv' AS row18
MERGE (station:Station {id: row18.station_id})
MERGE (subpanel:Subpanel {id: row18.subpanel_id})
MERGE (station)-[r:CONNECTED_TO]->(subpanel)
ON CREATE SET r.connected_on = datetime(row18.connected_on);

// Station → DeploymentBatch (TAGGED_WITH)
LOAD CSV WITH HEADERS FROM 'file:///stationDeploymentBatchRelationships.csv' AS row19
MERGE (station:Station {id: row19.station_id})
MERGE (batch:DeploymentBatch {id: row19.batch_id})
MERGE (station)-[r:TAGGED_WITH]->(batch)
ON CREATE SET r.tagged_on = date(row19.tagged_on);

// Station → Site (WITHIN)
LOAD CSV WITH HEADERS FROM 'file:///stationSiteRelationships.csv' AS row20
MERGE (station:Station {id: row20.station_id})
MERGE (site:Site {id: row20.site_id})
MERGE (station)-[r:WITHIN]->(site)
ON CREATE SET r.assigned_on = datetime(row20.assigned_on);

// ConnectorRecoiler nodes
LOAD CSV WITH HEADERS FROM 'file:///connectorRecoilers.csv' AS row21
MERGE (recoiler:ConnectorRecoiler {id: row21.recoiler_id})
ON CREATE SET recoiler.model = row21.model,
              recoiler.spring_rating = toFloat(row21.spring_rating),
              recoiler.installed_on = datetime(row21.installed_on),
              recoiler.serviced_on = CASE WHEN row21.serviced_on <> "" THEN datetime(row21.serviced_on) ELSE NULL END;

// Station → ConnectorRecoiler
LOAD CSV WITH HEADERS FROM 'file:///stationRecoilerRelationships.csv' AS row22
MERGE (station:Station {id: row22.station_id})
MERGE (recoiler:ConnectorRecoiler {id: row22.recoiler_id})
MERGE (station)-[r:HAS_RECOILER]->(recoiler)
ON CREATE SET r.installed_on = datetime(row22.installed_on);

// Station → EVSE (CONTAINS)
LOAD CSV WITH HEADERS FROM 'file:///stationEVSERelationships.csv' AS row23
MERGE (station:Station {id: row23.station_id})
MERGE (evse:EVSE {id: row23.evse_id})
MERGE (station)-[r:CONTAINS]->(evse)
ON CREATE SET r.position = toInteger(row23.position),
              r.orientation_override = row23.orientation_override,
              r.added = datetime(row23.added);

// EVSE ← Station (duplicate path, ensure same semantics)
LOAD CSV WITH HEADERS FROM 'file:///evseStationRelationships.csv' AS row24
MATCH (station:Station {id: row24.station_id})
MATCH (evse:EVSE {id: row24.evse_id})
MERGE (station)-[r:CONTAINS]->(evse)
ON CREATE SET r.added = datetime(row24.added);

// Kiosks
LOAD CSV WITH HEADERS FROM 'file:///kiosk.csv' AS row25
MERGE (kiosk:Kiosk {id: row25.kiosk_id})
ON CREATE SET kiosk.name = row25.name,
              kiosk.terminal = row25.terminal_type,
              kiosk.location = point({latitude: toFloat(row25.latitude), longitude: toFloat(row25.longitude)}),
              kiosk.created = datetime(row25.created);

// EVSEGroup → Kiosk
LOAD CSV WITH HEADERS FROM 'file:///groupKioskeRelationships.csv' AS row26
MATCH (group:EVSEGroup {id: row26.group_id})
MATCH (kiosk:Kiosk {id: row26.kiosk_id})
MERGE (group)-[r:TARGETS_KIOSK]->(kiosk)
ON CREATE SET r.created = datetime(row26.created);

// CCRs (Credit Card Readers)
LOAD CSV WITH HEADERS FROM 'file:///ccr.csv' AS row27
MERGE (ccr:CCR {id: row27.ccr_id})
ON CREATE SET ccr.vendor = row27.vendor,
              ccr.model = row27.model,
              ccr.created = datetime(row27.created);

// EVSE → CCR
LOAD CSV WITH HEADERS FROM 'file:///evseCCRRelationships.csv' AS row28
MATCH (evse:EVSE {id: row28.evse_id})
MATCH (ccr:CCR {id: row28.ccr_id})
MERGE (evse)-[r:EMBEDDED_CCR]->(ccr)
ON CREATE SET r.position = toInteger(row28.position),
              r.created = datetime(row28.created);

// Kiosk → CCR
LOAD CSV WITH HEADERS FROM 'file:///kioskCCRRelationships.csv' AS row29
MATCH (kiosk:Kiosk {id: row29.kiosk_id})
MATCH (ccr:CCR {id: row29.ccr_id})
MERGE (kiosk)-[r:EMBEDDED_CCR]->(ccr)
ON CREATE SET r.position = toInteger(row29.position),
              r.created = datetime(row29.created);

// Power Companies
LOAD CSV WITH HEADERS FROM 'file:///powerCompanies.csv' AS row30
MERGE (company:PowerCompany {id: row30.company_id})
ON CREATE SET company.name = row30.company_name,
              company.country = row30.country,
              company.website = row30.website;

// Power Accounts
LOAD CSV WITH HEADERS FROM 'file:///powerAccounts.csv' AS row31
MERGE (account:PowerAccount {id: row31.account_id})
ON CREATE SET account.number = row31.account_number,
              account.description = row31.description;

// Power Feeds
LOAD CSV WITH HEADERS FROM 'file:///powerFeed.csv' AS row32
MERGE (feed:PowerFeed {id: row32.feed_id})
ON CREATE SET feed.capacity_kw = toFloat(row32.capacity_kw),
              feed.label = row32.description;

// Subpanels
LOAD CSV WITH HEADERS FROM 'file:///subpanel.csv' AS row33
MATCH (company:PowerCompany {id: row33.company_id})
MERGE (subpanel:Subpanel {id: row33.subpanel_id})
ON CREATE SET subpanel.name = row33.name,
              subpanel.capacity_amps = toInteger(row33.capacity_amps),
              subpanel.voltage_v = toInteger(row33.voltage_v)
MERGE (subpanel)-[:SUPPLIED_BY]->(company);

// Subpanel → EVSE
LOAD CSV WITH HEADERS FROM 'file:///evseSubpanelRelationship.csv' AS row34
MATCH (evse:EVSE {id: row34.evse_id})
MATCH (subpanel:Subpanel {id: row34.subpanel_id})
MERGE (subpanel)-[r:SUPPLIES]->(evse)
ON CREATE SET r.started = datetime(row34.started);

// Subpanel → PowerFeed
LOAD CSV WITH HEADERS FROM 'file:///subpanelPowerFeedRelationship.csv' AS row35
MATCH (subpanel:Subpanel {id: row35.subpanel_id})
MATCH (feed:PowerFeed {id: row35.feed_id})
MERGE (subpanel)-[r:UNDER_FEED]->(feed)
ON CREATE SET r.started = datetime(row35.started);

// Subpanel → PowerAccount
LOAD CSV WITH HEADERS FROM 'file:///subpanelPowerAccountRelationship.csv' AS row36
MATCH (subpanel:Subpanel {id: row36.subpanel_id})
MATCH (account:PowerAccount {id: row36.account_id})
MERGE (subpanel)-[r:USES_ACCOUNT]->(account)
ON CREATE SET r.started = datetime(row36.started);

// PowerAccount → PowerType
LOAD CSV WITH HEADERS FROM 'file:///powerAccountPowerTypeRelationship.csv' AS row37
MATCH (account:PowerAccount {id: row37.account_id})
MATCH (type:PowerType {type: row37.power_type})
MERGE (account)-[:CLASSIFIED_AS]->(type);

// Green Programs
LOAD CSV WITH HEADERS FROM 'file:///greenPrograms.csv' AS row38
MERGE (program:GreenProgram {id: row38.program_id})
ON CREATE SET program.name = row38.name,
              program.description = row38.description;

// Organization → GreenProgram
LOAD CSV WITH HEADERS FROM 'file:///organizationGreenProggramRelationship.csv' AS row39
MATCH (org:Organization {id: row39.org_id})
MATCH (program:GreenProgram {id: row39.program_id})
MERGE (org)-[r:ENROLLED_IN]->(program)
ON CREATE SET r.started = datetime(row39.started);

// Drivers
LOAD CSV WITH HEADERS FROM 'file:///drivers.csv' AS row40
MERGE (driver:Driver {id: row40.driver_id})
ON CREATE SET driver.name = row40.name,
              driver.email = row40.email;

// Driver → EVSEGroup
LOAD CSV WITH HEADERS FROM 'file:///driverGroupRelationships.csv' AS row41
MATCH (driver:Driver {id: row41.driver_id})
MATCH (group:EVSEGroup {id: row41.group_id})
MERGE (driver)-[r:ALLOWED_IN]->(group)
ON CREATE SET r.role = row41.role,
              r.started = datetime(row41.started),
              r.ended = CASE WHEN row41.ended <> "" THEN datetime(row41.ended) ELSE NULL END;

// Credentials
LOAD CSV WITH HEADERS FROM 'file:///credential.csv' AS row42
MERGE (credential:Credential {id: row42.credential_id})
ON CREATE SET credential.type = row42.type,
              credential.format = row42.format,
              credential.scope = row42.scope,
              credential.issued = datetime(row42.issued);

// Credential Issuers
LOAD CSV WITH HEADERS FROM 'file:///credentialIssuer.csv' AS row43
MERGE (issuer:CredentialIssuer {id: row43.issuer_id})
ON CREATE SET issuer.name = row43.name,
              issuer.url = row43.url;

// Credential → Issuer
LOAD CSV WITH HEADERS FROM 'file:///credentialCredentialIssuerRelationships.csv' AS row44
MATCH (credential:Credential {id: row44.credential_id})
MATCH (issuer:CredentialIssuer {id: row44.issuer_id})
MERGE (credential)-[r:ISSUED_BY]->(issuer)
ON CREATE SET r.issued = datetime(row44.issued);

// Driver → Credential
LOAD CSV WITH HEADERS FROM 'file:///driversCredentialRelationships.csv' AS row45
MATCH (driver:Driver {id: row45.driver_id})
MATCH (credential:Credential {id: row45.credential_id})
MERGE (driver)-[r:HAS_CREDENTIAL]->(credential)
ON CREATE SET r.assigned = datetime(row45.assigned);
// Physical Tokens
LOAD CSV WITH HEADERS FROM 'file:///physicalToken.csv' AS row46
MERGE (token:PhysicalToken {id: row46.token_id})
ON CREATE SET token.type = row46.type,
              token.serial = row46.serial;

// PhysicalToken → Driver
LOAD CSV WITH HEADERS FROM 'file:///physicalTokenDriverRelationships.csv' AS row47
MATCH (token:PhysicalToken {id: row47.token_id})
MATCH (driver:Driver {id: row47.driver_id})
MERGE (token)-[r:ISSUED_TO]->(driver)
ON CREATE SET r.issued = datetime(row47.issued);

// Credential ↔ PhysicalToken
LOAD CSV WITH HEADERS FROM 'file:///credentialPhysicalTokenRelationships.csv' AS row48
MATCH (credential:Credential {id: row48.credential_id})
MATCH (token:PhysicalToken {id: row48.token_id})
MERGE (credential)-[:BACKED_BY]->(token);

// Access Policies
LOAD CSV WITH HEADERS FROM 'file:///accessPolicies.csv' AS row49
MERGE (policy:AccessPolicy {id: row49.policy_id})
ON CREATE SET policy.name = row49.name,
              policy.type = row49.type,
              policy.schedule_json = row49.schedule_json,
              policy.roles_allowed = split(row49.roles_allowed, ";");

// Policy → EVSEGroup
LOAD CSV WITH HEADERS FROM 'file:///accessPolicyEvseGroupRelationships.csv' AS row50
MATCH (policy:AccessPolicy {id: row50.policy_id})
MATCH (group:EVSEGroup {id: row50.group_id})
MERGE (group)-[:ENFORCES]->(policy);

// Policy → EVSE
LOAD CSV WITH HEADERS FROM 'file:///accessPolicyEvseRelationships.csv' AS row51
MATCH (policy:AccessPolicy {id: row51.policy_id})
MATCH (evse:EVSE {id: row51.evse_id})
MERGE (evse)-[:ENFORCES]->(policy);

// GeoZones
LOAD CSV WITH HEADERS FROM 'file:///geoZones.csv' AS row52
MERGE (zone:GeoZone {id: row52.zone_id})
ON CREATE SET zone.name = row52.name,
              zone.description = row52.description;

// Org → GeoZone
LOAD CSV WITH HEADERS FROM 'file:///organizationGeoZoneRelationships.csv' AS row53
MATCH (org:Organization {id: row53.org_id})
MATCH (zone:GeoZone {id: row53.zone_id})
MERGE (org)-[:IN_ZONE]->(zone);

// Deployment Batches
LOAD CSV WITH HEADERS FROM 'file:///deploymentBatch.csv' AS row54
MERGE (batch:DeploymentBatch {id: row54.batch_id})
ON CREATE SET batch.name = row54.name,
              batch.deployed_on = date(row54.deployed_on);

// Batch → EVSE
LOAD CSV WITH HEADERS FROM 'file:///deployentBatchEvseRelationships.csv' AS row55
MATCH (batch:DeploymentBatch {id: row55.batchId})
MATCH (evse:EVSE {id: row55.evseId})
MERGE (batch)-[:INCLUDES]->(evse);

// Maintainers
LOAD CSV WITH HEADERS FROM 'file:///maintainer.csv' AS row56
MERGE (maintainer:Maintainer {id: row56.maintainerId})
ON CREATE SET maintainer.name = row56.name,
              maintainer.company = row56.company;

// Maintainer → Site
LOAD CSV WITH HEADERS FROM 'file:///maintainerSiteRelationships.csv' AS row57
MATCH (maintainer:Maintainer {id: row57.maintainerId})
MATCH (site:Site {id: row57.siteId})
MERGE (maintainer)-[r:CONTRACTED_FOR]->(site)
ON CREATE SET r.since = datetime(row57.since);

// Maintainer → EVSE
LOAD CSV WITH HEADERS FROM 'file:///maintainerEvseRelationships.csv' AS row58
MATCH (maintainer:Maintainer {id: row58.maintainerId})
MATCH (evse:EVSE {id: row58.evseId})
MERGE (maintainer)-[r:INSTALLED]->(evse)
ON CREATE SET r.date = date(row58.installedOn);

// Batch → Maintainer
LOAD CSV WITH HEADERS FROM 'file:///deploymentBatchMaintanerRelationships.csv' AS row59
MATCH (batch:DeploymentBatch {id: row59.batchId})
MATCH (maintainer:Maintainer {id: row59.maintainerId})
MERGE (batch)-[r:EXECUTED_BY ]->(maintainer)
ON CREATE SET r.installed_on = datetime(row59.installed_on);

// Signage
LOAD CSV WITH HEADERS FROM 'file:///signage.csv' AS row61
MATCH (station:Station {id: row61.station_id})
MERGE (sign:Signage {id: row61.sign_id})
ON CREATE SET sign.type = row61.type,
              sign.content = row61.content,
              sign.installed_on = datetime(row61.installed_on)
WITH station, sign, row61
MERGE (station)-[r:HAS_SIGNAGE]->(sign)
ON CREATE SET r.installed_on = datetime(row61.installed_on);

// Lighting Fixtures
LOAD CSV WITH HEADERS FROM 'file:///lightingFixtures.csv' AS row62
MATCH (station:Station {id: row62.station_id})
MERGE (fixture:LightingFixture {id: row62.fixture_id})
ON CREATE SET fixture.fixture_type = row62.fixture_type,
              fixture.lumen = toInteger(row62.lumen),
              fixture.installed_on = datetime(row62.installed_on),
              fixture.last_maintenance = CASE WHEN row62.last_maintenance <> "" THEN datetime(row62.last_maintenance) ELSE NULL END
WITH station, fixture, row62
MERGE (station)-[r:HAS_LIGHTING]->(fixture)
ON CREATE SET r.installed_on = datetime(row62.installed_on);

// Bike Racks
LOAD CSV WITH HEADERS FROM 'file:///bikeRacks.csv' AS row63
MATCH (station:Station {id: row63.station_id})
MERGE (rack:BikeRack {id: row63.rack_id})
ON CREATE SET rack.rack_type = row63.rack_type,
              rack.capacity = toInteger(row63.capacity),
              rack.installed_on = datetime(row63.installed_on)
WITH station, rack, row63
MERGE (station)-[r:HAS_BIKE_RACK]->(rack)
ON CREATE SET r.installed_on = datetime(row63.installed_on);

// Solar Arrays
LOAD CSV WITH HEADERS FROM 'file:///solarArrays.csv' AS row64
MATCH (station:Station {id: row64.station_id})
MERGE (array:SolarArray {id: row64.array_id})
ON CREATE SET array.panel_count = toInteger(row64.panel_count),
              array.capacity_kw = toFloat(row64.capacity_kw),
              array.installed_on = datetime(row64.installed_on)
WITH station, array, row64
MERGE (station)-[r:HAS_SOLAR_ARRAY]->(array)
ON CREATE SET r.installed_on = datetime(row64.installed_on);

// Cameras
LOAD CSV WITH HEADERS FROM 'file:///cameras.csv' AS row65
MATCH (station:Station {id: row65.station_id})
MERGE (camera:Camera {id: row65.camera_id})
ON CREATE SET camera.model = row65.model,
              camera.resolution = row65.resolution,
              camera.installed_on = datetime(row65.installed_on),
              camera.location_description = row65.location_description
WITH station, camera, row65
MERGE (station)-[r:HAS_CAMERA]->(camera)
ON CREATE SET r.installed_on = datetime(row65.installed_on);


// ─── NODE-KEY CONSTRAINTS (id as PK + NOT NULL) ────────────────────────────

// Organization.id
CREATE CONSTRAINT organization_id_node_key IF NOT EXISTS
FOR (o:Organization)
REQUIRE (o.id) IS NODE KEY;

// Site.id
CREATE CONSTRAINT site_id_node_key IF NOT EXISTS
FOR (s:Site)
REQUIRE (s.id) IS NODE KEY;

// EVSEGroup.id
CREATE CONSTRAINT evsegroup_id_node_key IF NOT EXISTS
FOR (g:EVSEGroup)
REQUIRE (g.id) IS NODE KEY;

// StationModel.id
CREATE CONSTRAINT stationmodel_id_node_key IF NOT EXISTS
FOR (m:StationModel)
REQUIRE (m.id) IS NODE KEY;

// StationMount.id
CREATE CONSTRAINT stationmount_id_node_key IF NOT EXISTS
FOR (m:StationMount)
REQUIRE (m.id) IS NODE KEY;

// Station.id
CREATE CONSTRAINT station_id_node_key IF NOT EXISTS
FOR (t:Station)
REQUIRE (t.id) IS NODE KEY;

// GreenProgram.id
CREATE CONSTRAINT greenprogram_id_node_key IF NOT EXISTS
FOR (p:GreenProgram)
REQUIRE (p.id) IS NODE KEY;

// Driver.id
CREATE CONSTRAINT driver_id_node_key IF NOT EXISTS
FOR (d:Driver)
REQUIRE (d.id) IS NODE KEY;

// Credential.id
CREATE CONSTRAINT credential_id_node_key IF NOT EXISTS
FOR (c:Credential)
REQUIRE (c.id) IS NODE KEY;

// SolarArray.id
CREATE CONSTRAINT solararray_id_node_key IF NOT EXISTS
FOR (a:SolarArray)
REQUIRE (a.id) IS NODE KEY;

// Camera.id
CREATE CONSTRAINT camera_id_node_key IF NOT EXISTS
FOR (c:Camera)
REQUIRE (c.id) IS NODE KEY;



// ─── ADDITIONAL INDEXES FOR COMMON LOOKUPS ────────────────────────────────────

// Organization lookup by name
CREATE INDEX organization_name_idx IF NOT EXISTS
FOR (o:Organization)
ON (o.name);

// Site lookup by name
CREATE INDEX site_name_idx IF NOT EXISTS
FOR (s:Site)
ON (s.name);

// EVSEGroup lookup by name
CREATE INDEX evsegroup_name_idx IF NOT EXISTS
FOR (g:EVSEGroup)
ON (g.name);

// StationModel lookup by name
CREATE INDEX stationmodel_name_idx IF NOT EXISTS
FOR (m:StationModel)
ON (m.name);

// Station lookup by address
CREATE INDEX station_address_idx IF NOT EXISTS
FOR (t:Station)
ON (t.address);

// Spatial index on Station.location
CREATE INDEX station_location_idx IF NOT EXISTS
FOR (t:Station)
ON (t.location);

// Driver lookup by email (fast login/lookup)
CREATE CONSTRAINT driver_email_unique IF NOT EXISTS
FOR (d:Driver)
REQUIRE d.email IS UNIQUE;

// Credential – if you query by type or scope
CREATE INDEX credential_type_idx IF NOT EXISTS
FOR (c:Credential)
ON (c.type);

CREATE INDEX credential_scope_idx IF NOT EXISTS
FOR (c:Credential)
ON (c.scope);