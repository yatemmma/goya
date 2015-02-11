CREATE TABLE "logs" (
	"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
	"uri" varchar(255), 
	"query" varchar(255), 
	"body" varchar(255), 
	"created_at" datetime, 
	"updated_at" datetime
	);