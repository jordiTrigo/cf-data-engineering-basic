CREATE TYPE "parameter_tipo" AS ENUM (
  'integer',
  'decimal',
  'string',
  'jsonb'
);

CREATE TABLE "Dim_Ambito" (
  "id" integer PRIMARY KEY,
  "name" VARCHAR(100),
  "desc" VARCHAR(250),
  "active" bool,
  "deleted" bool,
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "Dim_Categoria" (
  "id" integer PRIMARY KEY,
  "ambito_id" integer,
  "name" VARCHAR(100),
  "desc" VARCHAR(250),
  "active" bool,
  "deleted" bool,
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "Dim_Tipo" (
  "id" integer PRIMARY KEY,
  "cat_id" integer,
  "name" VARCHAR(100) UNIQUE,
  "model" VARCHAR(100),
  "desc" VARCHAR(250),
  "tablename" VARCHAR(100) UNIQUE,
  "decoder_payload_class" VARCHAR(100),
  "active" bool,
  "deleted" bool,
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "Dim_Location" (
  "id" integer PRIMARY KEY,
  "name" VARCHAR(100),
  "desc" VARCHAR(250),
  "geospatial_point" POINT,
  "active" bool,
  "deleted" bool,
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "Dim_Unit" (
  "id" integer PRIMARY KEY,
  "name" VARCHAR(100),
  "desc" VARCHAR(250),
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "Dim_Sensor" (
  "id" integer PRIMARY KEY,
  "tipo_id" integer,
  "location_id" integer,
  "name" VARCHAR(100),
  "desc" VARCHAR(250),
  "active" bool,
  "deleted" bool,
  "created_at" timestamp,
  "updated_at" timestamp,
  PRIMARY KEY ("tipo_id", "name")
);

CREATE TABLE "Dim_Parameter" (
  "id" integer PRIMARY KEY,
  "name" VARCHAR(100),
  "description" VARCHAR(250),
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "Dim_SensorParameter" (
  "id" integer PRIMARY KEY,
  "sensor_id" integer,
  "parameter_id" integer,
  "tipo" parameter_tipo,
  "unit_id" integer,
  "max_value" decimal,
  "min_value" decimal,
  PRIMARY KEY ("sensor_id", "parameter_id")
);

CREATE TABLE "Dim_Date" (
  "id" integer PRIMARY KEY,
  "date_at" date,
  "year_at" tinyint,
  "month_at" tinyint,
  "day_at" tinyint
);

CREATE TABLE "Dim_Time" (
  "id" integer PRIMARY KEY,
  "hour_at" tinyint,
  "minute_at" tinyint,
  "second_at" tinyint
);

CREATE TABLE "Fact_Measurement_Raw" (
  "id" integer PRIMARY KEY,
  "sensor_id" integer,
  "tipo_id" integer,
  "date_id" integer,
  "time_id" integer,
  "values" JSONB,
  "date_registered" timestamp,
  "created_at" timestamp,
  "updated_at" timestamp,
  "is_processed" bool,
  "date_processed" timestamp
);

CREATE TABLE "Fact_Measurement_AllParam" (
  "id" integer PRIMARY KEY,
  "sensor_id" integer,
  "tipo_id" integer,
  "date_id" integer,
  "time_id" integer,
  "values" JSONB,
  "date_registered" timestamp,
  "created_at" timestamp,
  "updated_at" timestamp,
  "date_processed" timestamp
);

CREATE TABLE "Fact_Measurement_ByParam" (
  "id" integer PRIMARY KEY,
  "sensor_id" integer,
  "tipo_id" integer,
  "date_id" integer,
  "time_id" integer,
  "sensorparameter_id" integer,
  "value" VARCHAR(250),
  "date_registered" timestamp,
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "Fact_Measurement_tablename" (
  "id" integer PRIMARY KEY,
  "sensor_id" integer,
  "tipo_id" integer,
  "date_id" integer,
  "time_id" integer,
  "presion" double,
  "humedad" double,
  "temperatura" double,
  "CO2" double,
  "NO2" double,
  "O3" double,
  "date_registered" timestamp,
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE INDEX ON "Dim_Categoria" ("ambito_id");

CREATE INDEX ON "Dim_Tipo" ("cat_id");

CREATE UNIQUE INDEX ON "Dim_Tipo" ("name");

CREATE UNIQUE INDEX ON "Dim_Tipo" ("tablename");

CREATE INDEX ON "Dim_Sensor" ("location_id");

CREATE INDEX ON "Dim_SensorParameter" ("unit_id");

CREATE INDEX ON "Fact_Measurement_Raw" ("sensor_id");

CREATE INDEX ON "Fact_Measurement_Raw" ("tipo_id");

CREATE INDEX ON "Fact_Measurement_Raw" ("is_processed");

CREATE INDEX ON "Fact_Measurement_Raw" ("date_id", "time_id");

CREATE INDEX ON "Fact_Measurement_AllParam" ("sensor_id");

CREATE INDEX ON "Fact_Measurement_AllParam" ("tipo_id");

CREATE INDEX ON "Fact_Measurement_AllParam" ("date_id", "time_id");

CREATE INDEX ON "Fact_Measurement_ByParam" ("sensor_id");

CREATE INDEX ON "Fact_Measurement_ByParam" ("tipo_id");

CREATE INDEX ON "Fact_Measurement_ByParam" ("date_id", "time_id");

CREATE INDEX ON "Fact_Measurement_tablename" ("sensor_id");

CREATE INDEX ON "Fact_Measurement_tablename" ("tipo_id");

CREATE INDEX ON "Fact_Measurement_tablename" ("date_id", "time_id");

COMMENT ON COLUMN "Fact_Measurement_Raw"."values" IS 'JSON con los valores registrados del sensor codificados en binario';

COMMENT ON COLUMN "Fact_Measurement_AllParam"."values" IS 'JSON con los valores registrados del sensor decodificados';

COMMENT ON COLUMN "Fact_Measurement_ByParam"."value" IS 'Valor registrado del sensor para el parámetro parameter_id';

ALTER TABLE "Dim_Ambito" ADD FOREIGN KEY ("id") REFERENCES "Dim_Categoria" ("ambito_id");

ALTER TABLE "Dim_Categoria" ADD FOREIGN KEY ("id") REFERENCES "Dim_Tipo" ("cat_id");

ALTER TABLE "Dim_Tipo" ADD FOREIGN KEY ("id") REFERENCES "Dim_Sensor" ("tipo_id");

ALTER TABLE "Dim_Location" ADD FOREIGN KEY ("id") REFERENCES "Dim_Sensor" ("location_id");

ALTER TABLE "Dim_Sensor" ADD FOREIGN KEY ("id") REFERENCES "Dim_SensorParameter" ("sensor_id");

ALTER TABLE "Dim_Unit" ADD FOREIGN KEY ("id") REFERENCES "Dim_SensorParameter" ("unit_id");

ALTER TABLE "Dim_Sensor" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_Raw" ("sensor_id");

ALTER TABLE "Dim_Tipo" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_Raw" ("tipo_id");

ALTER TABLE "Dim_Date" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_Raw" ("date_id");

ALTER TABLE "Dim_Time" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_Raw" ("time_id");

ALTER TABLE "Dim_Sensor" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_AllParam" ("sensor_id");

ALTER TABLE "Dim_Tipo" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_AllParam" ("tipo_id");

ALTER TABLE "Dim_Date" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_AllParam" ("date_id");

ALTER TABLE "Dim_Time" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_AllParam" ("time_id");

ALTER TABLE "Dim_Sensor" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_ByParam" ("sensor_id");

ALTER TABLE "Dim_Tipo" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_ByParam" ("tipo_id");

ALTER TABLE "Dim_Date" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_ByParam" ("date_id");

ALTER TABLE "Dim_Time" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_ByParam" ("time_id");

ALTER TABLE "Dim_SensorParameter" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_ByParam" ("sensorparameter_id");

ALTER TABLE "Dim_Parameter" ADD FOREIGN KEY ("id") REFERENCES "Dim_SensorParameter" ("parameter_id");

ALTER TABLE "Dim_Sensor" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_tablename" ("sensor_id");

ALTER TABLE "Dim_Tipo" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_tablename" ("tipo_id");

ALTER TABLE "Dim_Date" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_tablename" ("date_id");

ALTER TABLE "Dim_Time" ADD FOREIGN KEY ("id") REFERENCES "Fact_Measurement_tablename" ("time_id");
