$connectionString = $OctopusParameters["Project.Database.ConnectionString"]
dotnet PetClinic-Dbup.dll "$connectionString"
