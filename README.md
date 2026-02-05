# Cafe Sales Data Cleaning with MySQL Overview

## Goal
I took a raw, messy dataset of cafe sales records and built a SQL script to clean it up for analysis. The goal wasn't just to delete bad rows, but to rescue as much data as possible using logic and math.

## The Problems
When I first loaded the `cafe_sales` data, it was pretty unusable:
*  Dirty Values: Columns had text like "ERROR" or "UNKNOWN" mixed in with actual numbers.
*  Wrong Data Types: Dates and prices were stored as text.
*  Logical Duplicates: Transactions that looked unique (different IDs) but had identical data.
*  Missing Info: Lots of blank spots in `Price Per Unit`, `Quantity`, and `Item` names.

## My Approach
You can follow the steps in `Cafe_sales_data_cleaning.sql`. Here is the logic behind what I did:

### 1. Safety First
I never touch the raw data. The first step creates a staging table (`cafe_sales_clean`) so I have a sandbox to work in.

### 2. Standardizing the Mess
Before I could convert data types, I had to deal with the garbage values. I ran updates to turn strings like "ERROR" and empty cells into proper SQL `NULL` values. This allowed me to safely convert columns to `INT`, `DECIMAL`, and `DATE` formats.

### 3. Filling In Missing Data (Imputation)
Instead of just `DELETE FROM table WHERE column IS NULL`, I tried to fill in the blanks:
* Math Logic:  Since `Total Spent = Price Per Unit * Quantity`, if I had two of those numbers, I calculated the missing third one.
* Context Logic: By reviewing, I noticed that specific items always had specific prices such as Salad was always $5.00. I wrote a `CASE` statement to fill in missing Items based on Price, and missing Price Per Unit based on Items.

### 4. The Tricky Duplicates
This was the hardest part. Standard SQL equality checks (`=`) fail when comparing `NULL` values.
To solve this, I used a self-join with the Spaceship Operator (`<=>`). This is a NULL-safe equality check that allowed me to find rows that were truly identical, even if they had empty fields. I kept the oldest duplicate records and removed the younger ones.

### 5. Final Touch-ups
At the end, I did a final sweep to remove rows that were too broken to fix like rows missing a Transaction Date and labeled the remaining unknown locations as "Unknown" so they wouldn't break visualization tools later.

## How to Run It
1. Import the raw `cafe_sales` table.
2. Run the script top-to-bottom.
3. Use `cafe_sales_clean` for your analysis.
