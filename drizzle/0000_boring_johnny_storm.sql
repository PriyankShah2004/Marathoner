CREATE TABLE "user_runs" (
	"user_id" integer NOT NULL,
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "user_runs_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"strava_id" text NOT NULL,
	"distance" real,
	"moving_time" integer,
	"total_elevation_gain" real,
	"start_date" timestamp with time zone NOT NULL,
	"average_heart_rate" real,
	"max_heart_rate" real,
	"metadata" jsonb,
	CONSTRAINT "user_runs_stravaId_unique" UNIQUE("strava_id")
);
--> statement-breakpoint
CREATE TABLE "users_table" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "users_table_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"strava_athlete_id" text NOT NULL,
	"first_name" text,
	"last_name" text,
	"profile_image_url" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "users_table_stravaAthleteId_unique" UNIQUE("strava_athlete_id")
);
--> statement-breakpoint
ALTER TABLE "user_runs" ADD CONSTRAINT "user_runs_user_id_users_table_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users_table"("id") ON DELETE no action ON UPDATE no action;