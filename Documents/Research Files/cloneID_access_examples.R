##Noemi has added you to the cloneid database, believe danielolofin is your username 
## and Karyotyping_Analysis is the password. Access is only possible when you are on the Moffitt network.
## If you email Noemi your home IP and/or moffitt guest IP she can give you access on those networks too.

#create user 'danielolofin'@'206.81.166.156' identified by 'Karyotyping_Analysis';
#GRANT SELECT ON *.* TO 'danielolofin'@'206.81.166.156';  
#create user 'danielolofin'@'192.168.1.32' identified by 'Karyotyping_Analysis';
#GRANT SELECT ON *.* TO 'danielolofin'@'192.168.1.32';  


library(RMariaDB)
db <- dbConnect(MariaDB(), dbname="CLONEID", 
                host="cloneid.cswgogbb5ufg.us-east-1.rds.amazonaws.com", 
                user="myuser", password="mypassword")

## this is the database containing all the data. I use R to work with it but if you have experience with SQL database interactions
## you can access with any other software you like
dbListTables(db)
#> dbListTables(db)
#[1] "CellLinesAndPatients"           "CellSurfaceMarkers_hg19"        "Crypgene_LiquidNitrogenBackup"  "Flask"                         
#[5] "FlowCytometry"                  "Identity"                       "IdentitySub"                    "LiquidNitrogen"                
#[9] "Loci"                           "Media"                          "MediaIngredients"               "Minus80Freezer"                
#[13] "Passaging"                      "Perspective"                    "PerspectivePartial"             "QuPathEvaluation"              
#[17] "ToDelete_MorphologyPerspective"

dbListFields(db,"Perspective") ##karyotype data is in here.
#[1] "whichPerspective" "size"             "parent"           "profile"          "profile_hash"     "origin"           "sampleSource"    
#[8] "coordinates"      "rootID"           "cloneID"          "profile_loci"     "state"            "alias"            "hasChildren"     
#[15] "transactionId"    "export4pub"  

dbListFields(db,"Passaging") ## a lot of the metadata is here
#> dbListFields(db,"Passaging")
#[1] "id"                          "cellLine"                    "event"                       "passaged_from_id1"          
#[5] "passaged_from_id2"           "growthType"                  "passage"                     "cellCount"                  
#[9] "date"                        "address"                     "comment"                     "media"                      
#[13] "feeding1"                    "feeding2"                    "feeding3"                    "feeding4"                   
#[17] "Countess"                    "feeding5"                    "feeding6"                    "feeding7"                   
#[21] "feeding8"                    "feeding9"                    "feeding10"                   "backup_cellCount"           
#[25] "feeding11"                   "feeding12"                   "feeding13"                   "feeding14"                  
#[29] "feeding15"                   "flask"                       "feeding16"                   "feeding17"                  
#[33] "backup_cellCount2"           "backup_cellCount_CLONEIDV14" "correctedCount"              "areaOccupied_um2"           
#[37] "cellSize_um2"                "owner"                       "lastModified"                "transactionId"              
#[41] "export4pub"

dbListFields(db,"Media") ## Media info, the id column here matches the media column inside passaging.
#[1] "id"                     "base1"                  "base1_pct"              "base2"                  "base2_pct"             
#[6] "FBS"                    "FBS_pct"                "EnergySource2"          "EnergySource2_pct"      "EnergySource"          
#[11] "EnergySource_nM"        "HEPES"                  "HEPES_mM"               "Salt"                   "Salt_nM"               
#[16] "antibiotic"             "antibiotic_pct"         "growthFactors"          "antibiotic2"            "antibiotic2_pct"       
#[21] "antimycotic"            "antimycotic_pct"        "Stressor"               "Stressor_concentration" "Stressor_unit"         
#[26] "comment"                "antibiotic3"            "antibiotic4"            "antibiotic3_pct"        "antibiotic4_pct"       
#[31] "oxygen_pct"             "export4pub" 


## this is how to pull the karyotype data from the perspective table. For this you'll need to know the origin.
## Perhaps vural can provide a list of all the origins that belong in the experiment. "Origin" maps to "id" field in the 
## passaging table.

q <- paste0("SELECT * FROM Perspective WHERE origin='SNU-668_G1_A10_seed' AND whichPerspective='GenomePerspective'")
rs <- dbSendQuery(db, q)

# Single query to pull all relevant profiles
q <- paste0("SELECT * FROM Perspective WHERE cloneID IN (", id_clause, ")")
rs <- dbSendQuery(db, q)
res <- dbFetch(rs)
dbClearResult(rs)

# Convert each BLOB to a double vector
kvecs <- lapply(res$profile, function(p) {
  raw_vec <- p
  readBin(raw_vec, what = "double", n = length(raw_vec) / 8, endian = "big")
})

# Stack into a matrix
kmat <- do.call(rbind, kvecs)
rownames(kmat) <- res$cloneID

##mkat is now a matrix where rows are cells, columns are chromosomes. This is from a single passage.





# Step 7: Run MANOVA to test overall karyotype differences by treatment
# (Assume the karyotype values are in the first N columns, e.g., 1:22)
manova_result <- manova(as.matrix(karyo_df[, 1:(ncol(karyo_df)-3)]) ~ treatment, data = karyo_df)
summary(manova_result, test = "Wilks")

# Step 8 (Optional): PCA visualization
pca <- prcomp(karyo_df[, 1:(ncol(karyo_df)-3)], scale. = TRUE)
plot(pca$x[,1:2], col = ifelse(karyo_df$treatment == "Control", "blue", "red"), pch = 19,
     xlab = "PC1", ylab = "PC2", main = "PCA of Karyotype Profiles")
legend("topright", legend = c("Control", "GlucoseDeprived"), col = c("blue", "red"), pch = 19)