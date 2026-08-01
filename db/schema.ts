import { integer, pgTable, varchar, serial, text, timestamp, real, jsonb } from "drizzle-orm/pg-core";

export const usersTable = pgTable("users_table", {
    id: integer().primaryKey().generatedAlwaysAsIdentity(),
    stravaAthleteId: text().notNull().unique(),
    firstName: text(),
    lastName: text(),
    profileImageUrl: text(),
    createdAt: timestamp({ withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp({ withTimezone: true }).notNull().defaultNow().$onUpdate(() => new Date()),
});

export const userRuns = pgTable("user_runs", {
    userId: integer().notNull().references(() => usersTable.id),
    id: integer().primaryKey().generatedAlwaysAsIdentity(),
    stravaId: text().notNull().unique(),
    distance: real(),
    movingTime: integer(),
    totalElevationGain: real(),
    startDate: timestamp({ withTimezone: true }).notNull(),
    averageHeartRate: real(),
    maxHeartRate: real(),
    metadata: jsonb(),
});

type SelectUser = typeof usersTable.$inferSelect;
type InserUser = typeof usersTable.$inferInsert;
