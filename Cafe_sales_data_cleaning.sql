-- DATA CLEANING OF CAFE_SALES--

-- We are going to:

-- Create a staging table
-- Remove duplicates
-- Treat the duplicates if there are
-- Standardized Empty Values to NULL
-- Standardized Dirty Values
-- Populate Missing Rows
-- Remove NULLS or Empty Values

-- I. Create a Staging Table--
	-- First, we must create a staging table, we must never clean our raw data directly. Create a copy to work on.
		CREATE TABLE cafe_sales_clean AS 
		SELECT * 
		FROM cafe_sales;


-- II. Determine and Remove Duplicates--
	-- The Transaction ID column is the unique id for the dataset, therefore we are going to check for duplicates
		SELECT `Transaction ID`, COUNT(*)                                                                                                                                                                            
		FROM cafe_sales_clean
		GROUP BY `Transaction ID`                                                                                                                                                                                          
		ORDER BY `Transaction ID` DESC;
		-- No duplicates--
        
	-- We don't have duplicates but we have logical duplicates, which have different transaction_id values, but the rest of the data is identical.
		SELECT COUNT(*) as duplicate_count, GROUP_CONCAT(`Transaction ID`) as list_of_ids, Item, `Transaction Date`
		FROM cafe_sales_clean
		GROUP BY Item, Quantity, `Price Per Unit`, `Transaction Date`
		HAVING duplicate_count > 1;



-- III. Standardized Empty Values to NULL--
	-- Our data has values like "ERROR", "UNKNOWN", and Empty values mixed with real data. We need to turn these into real SQL NULL values so calculations will work later.
	-- To visualize it
		SELECT * 
		FROM cafe_sales_clean
		ORDER BY 1;

	-- CLEAN NUMERIC COLUMNS:
		-- Fix Quantity
		UPDATE cafe_sales_clean 
		SET Quantity = NULL 
		WHERE Quantity IN ('ERROR', 'UNKNOWN', '');

		-- Fix Price
		UPDATE cafe_sales_clean 
		SET `Price Per Unit` = NULL 
		WHERE `Price Per Unit` IN ('ERROR', 'UNKNOWN', '');

		-- Fix Total Spent
		UPDATE cafe_sales_clean 
		SET `Total Spent` = NULL 
		WHERE `Total Spent` IN ('ERROR', 'UNKNOWN', '');

	-- CLEAN TEXT COLUMNS:
		UPDATE cafe_sales_clean 
		SET `Payment Method` = NULL 
		WHERE `Payment Method` IN ('UNKNOWN', 'ERROR', '');

		UPDATE cafe_sales_clean 
		SET Location = NULL 
		WHERE Location IN ('UNKNOWN', 'ERROR', '');

		UPDATE cafe_sales_clean 
		SET Item = NULL 
		WHERE Item IN ('UNKNOWN', 'ERROR', '');



-- IV. Standardized Dirty Values --
	-- Fix Data Types
		-- Numeric columns are likely stored as text because they contained words like "ERROR". Now that we removed them, we must convert the columns to integers.
        -- Also, converting Text format to Varchar or the appropriate type for each columns.

	-- Convert Quantity to Integer
		ALTER TABLE cafe_sales_clean 
		MODIFY COLUMN Quantity INT;

	-- Convert Price Per Unit and Total Spent to Decimal 
		ALTER TABLE cafe_sales_clean 
		MODIFY COLUMN `Price Per Unit` DECIMAL(5, 2);

		ALTER TABLE cafe_sales_clean 
		MODIFY COLUMN `Total Spent` DECIMAL(5, 2);
	
	-- Fix Date Format
			-- Convert UKNOWN, ERROR, and Empty values to null
				UPDATE cafe_sales_clean
				SET `Transaction Date` = NULL
				WHERE `Transaction Date` IN ('UNKNOWN', 'ERROR', '');
				ALTER TABLE cafe_sales_clean MODIFY COLUMN `Price Per Unit` DECIMAL(5,2);
                
			-- Convert the text type to date type 
				ALTER TABLE cafe_sales_clean 
				MODIFY COLUMN `Transaction Date` DATE;
                
			-- Convert Transaction ID, Payment Method, and Location to Varchar
				ALTER TABLE cafe_sales_clean 
				MODIFY COLUMN `Transaction ID` Varchar(255), 
                MODIFY COLUMN `Payment Method` Varchar (255),
                MODIFY COLUMN Location Varchar (255)
                ;
                                
	
        
-- V. Populate missing rows--
	-- Calculating Null Values of Total Spent by multiplying Quantity and Price Per Unit
		UPDATE cafe_sales_clean
		SET `Total Spent` = Quantity * `Price Per Unit`
		WHERE `Total Spent` IS NULL 
		AND Quantity IS NOT NULL 
		AND `Price Per Unit` IS NOT NULL;
        
	-- Calculating Null Values of Price Per Unit by dividing Total Spent with Quantity
		UPDATE cafe_sales_clean
		SET `Price Per Unit` = `Total Spent` / Quantity
		WHERE `Price Per Unit` IS NULL 
		AND `Total Spent` IS NOT NULL 
		AND Quantity IS NOT NULL 
		AND Quantity > 0;
        
	-- Calculating Null Values of Quantity by dividing Total Spent with Price Per Unit 
		UPDATE cafe_sales_clean
		SET Quantity = `Total Spent` / `Price Per Unit`
		WHERE Quantity IS NULL 
		AND `Total Spent` IS NOT NULL 
		AND `Price Per Unit` IS NOT NULL 
		AND `Price Per Unit` > 0;
        
	-- Some of the Items are null but based on other items that have Price Per Unit, we can determine what item it is and vice versa.
		SELECT DISTINCT Item, `Price Per Unit`
		FROM cafe_sales_clean;
        
		-- Filling up Price Per Unit based from Items
			UPDATE cafe_sales_clean
			SET `Price Per Unit` = CASE Item
				WHEN 'Cake' THEN 3.00
				WHEN 'Coffee' THEN 2.00
				WHEN 'Cookie' THEN 1.00
				WHEN 'Juice' THEN 3.00
				WHEN 'Salad' THEN 5.00
				WHEN 'Sandwich' THEN 4.00
				WHEN 'Smoothie' THEN 4.00
				WHEN 'Tea' THEN 1.50
			END
			WHERE `Price Per Unit` IS NULL 
			AND Item IN ('Cake', 'Coffee', 'Cookie', 'Juice', 'Salad', 'Sandwich', 'Smoothie', 'Tea');
        
		-- Filling up Items based from Price Per Unit 
			UPDATE cafe_sales_clean
			SET Item = CASE 
				WHEN `Price Per Unit` = 5.00 THEN 'Salad'
				WHEN `Price Per Unit` = 2.00 THEN 'Coffee'
				WHEN `Price Per Unit` = 1.50 THEN 'Tea'
				WHEN `Price Per Unit` = 1.00 THEN 'Cookie'
			END
			WHERE Item IS NULL 
			AND `Price Per Unit` IN (5.00, 2.00, 1.50, 1.00);
          
          
		-- By filling in nullvalues of Price Per Unit and Quantities. It enable us to work on rows that it couldn't fix before.
        -- Re-run Calculation for Total Spent
			UPDATE cafe_sales_clean
			SET `Total Spent` = Quantity * `Price Per Unit`
			WHERE `Total Spent` IS NULL 
			AND Quantity IS NOT NULL 
			AND `Price Per Unit` IS NOT NULL;
          
          
-- VI. Final Touch-ups --
	-- Since, we still have logical duplicates after filling up UNKNOWN, ERROR, and Empty values, we must then delete it by using the spaceship operator "<=>". 
    -- It is the best way to find logical duplicates because it refuses to let the NULL values hide a match.
            SELECT * FROM cafe_sales_clean t1
			INNER JOIN cafe_sales_clean t2 
			WHERE 
					t1.Item = t2.Item AND 
					t1.Quantity = t2.Quantity AND 
					t1.`Price Per Unit` = t2.`Price Per Unit` AND 
					t1.`Transaction Date` = t2.`Transaction Date` AND
					t1.`Transaction ID` > t2.`Transaction ID`; 
                    
	-- Before executing the deletion, we must modify the specific column that we will use into VARCHARsince it is a TEXT 
    -- Then, create index on the columns that are basis for duplicates.
			ALTER TABLE cafe_sales_clean MODIFY COLUMN Item VARCHAR(255);
            
			CREATE INDEX index_find_duplicates
			ON cafe_sales_clean (Item, Quantity, `Price Per Unit`, `Transaction Date`);
            
	-- The spacehip operator or null-safe operator (<=>) process exists because standard SQL treats blanks as non-existent.
    -- Also, the mechanism requires direct comparison of all database columns to find and eliminate duplicate entries, leaving behind the original record.
    
            DELETE t1 
            FROM cafe_sales_clean t1
			INNER JOIN cafe_sales_clean t2 
			WHERE 
				t1.Item <=> t2.Item AND 
				t1.Quantity <=> t2.Quantity AND 
				t1.`Price Per Unit` <=> t2.`Price Per Unit` AND 
				t1.`Transaction Date` <=> t2.`Transaction Date` AND
				t1.`Transaction ID` > t2.`Transaction ID`;
                

		-- To determine the numbers of all nulls after filling in and sorting the data.
			SELECT 
				SUM(`Transaction ID` IS NULL) AS Missing_IDs,
				SUM(Item IS NULL) AS Missing_Items,
				SUM(Quantity IS NULL) AS Missing_Quantities,
				SUM(`Price Per Unit` IS NULL) AS Missing_Prices,
				SUM(`Total Spent` IS NULL) AS Missing_Totals,
				SUM(`Payment Method` IS NULL) AS Missing_Payments,
				SUM(Location IS NULL) AS Missing_Locations,
				SUM(`Transaction Date` IS NULL) AS Missing_Dates
			FROM cafe_sales_clean;


    
	-- Since Payment Method have only 6 NULLS, we can then delete it because it will have no effect in our total data analysis and visualizations.
		SELECT * 
		FROM cafe_sales_clean 
		WHERE `Price Per Unit` IS NULL;
     
		DELETE 
		FROM cafe_sales_clean 
		WHERE `Price Per Unit` IS NULL;
    
	-- Since Total Spent have only 20 NULLS, we can then delete it because it will have no effect in our total data analysis and visualizations.
        SELECT * 
		FROM cafe_sales_clean 
		WHERE `Total Spent` IS NULL;    
        
		DELETE 
		FROM cafe_sales_clean 
		WHERE `Total Spent` IS NULL;
        
	-- Since Transaction Date have only 52 NULLS, we can then delete it because it will have no effect in our total data analysis and visualizations.  
		SELECT * 
		FROM cafe_sales_clean 
		WHERE `Transaction Date` IS NULL;  
	
		DELETE 
		FROM cafe_sales_clean 
		WHERE `Transaction Date` IS NULL;
        
	-- Since Quantity have only 13 NULLS, we can then delete it because it will have no effect in our total data analysis and visualizations.  
		SELECT * 
		FROM cafe_sales_clean 
		WHERE Quantity IS NULL;
        
        DELETE 
		FROM cafe_sales_clean 
		WHERE Quantity IS NULL;
        
        -- Since Items have only 418 NULLS, we can then delete it because it will have no effect in our total data analysis and visualizations.  
		SELECT * 
		FROM cafe_sales_clean 
		WHERE Item IS NULL;
        
        DELETE 
		FROM cafe_sales_clean 
		WHERE Item IS NULL;
        
        
        
        -- As we can see, null and empty values in Payment Method and Location can affect our analysis
        -- We must have to convert it to Unknown.
        
        -- Fix missing Payment Methods
				UPDATE cafe_sales_clean
				SET `Payment Method` = 'Unknown'
				WHERE `Payment Method` IS NULL OR `Payment Method` = '';

		--  Fix missing Locations
				UPDATE cafe_sales_clean
				SET `Location` = 'Unknown'
				WHERE `Location` IS NULL OR `Location` = '';
                
		-- Visualize it--
			select *
			from cafe_sales_clean
			Order by 1;