-- AlterTable
ALTER TABLE "goals" ADD COLUMN     "planned_date" TEXT;

-- CreateTable
CREATE TABLE "commitments" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "start_date" TEXT NOT NULL,
    "start_minute" INTEGER NOT NULL,
    "end_minute" INTEGER NOT NULL,
    "recurrence_weekdays" INTEGER[],
    "recurrence_end_date" TEXT,
    "recurring" BOOLEAN NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "commitments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commitment_exceptions" (
    "id" UUID NOT NULL,
    "commitment_id" UUID NOT NULL,
    "date" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "new_date" TEXT,
    "start_minute" INTEGER,
    "end_minute" INTEGER,

    CONSTRAINT "commitment_exceptions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "commitments_user_id_idx" ON "commitments"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "commitment_exceptions_commitment_id_date_key" ON "commitment_exceptions"("commitment_id", "date");

-- AddForeignKey
ALTER TABLE "commitments" ADD CONSTRAINT "commitments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commitment_exceptions" ADD CONSTRAINT "commitment_exceptions_commitment_id_fkey" FOREIGN KEY ("commitment_id") REFERENCES "commitments"("id") ON DELETE CASCADE ON UPDATE CASCADE;
