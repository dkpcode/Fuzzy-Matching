USE [Donnie_Test]
GO
/****** Object:  StoredProcedure [dbo].[spCompanyMatch]    Script Date: 6/10/2020 9:22:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spCompanyMatch](@pct int) as

BEGIN TRANSACTION

declare @cnt int
set @cnt = @pct

declare @cs_id int
declare @companyName nvarchar(100)
declare @custname nvarchar(200)
declare @sql nvarchar(max) 
-- local means the cursor name is private to this code
-- fast_forward enables some speed optimizations
declare cursorNullcoid cursor local fast_forward for
 SELECT  cs_id, company, cust_name	
   FROM donnie_test.dbo.customers
  WHERE co_id is null and company is not null;
    

open cursorNullcoid
-- Instead of fetching twice, I rather set up no-exit loop
while 1 = 1
BEGIN
  -- And then fetch
  fetch next from cursorNullcoid into @cs_id, @companyName, @custname
  -- And then, if no row is fetched, exit the loop
  
  if @@fetch_status <> 0
  begin
     break
  end
  -- Quotename is needed if you ever use special characters
  -- in table/column names. Spaces, reserved words etc.
  -- Other changes add apostrophes at right places.
  set @sql = N'
  with cte(co_id, name, name_noltd,cs_id, custco, custname,matchpct) as (
  SELECT *, '+ quotename(@cs_id,'''')+ ' as CS_ID, ' + quotename(@companyName,'''') + ' as custCO, ' + quotename(@custname,'''') +
				' as custname, dbo.Levenshtein_pct( name,'  +   quotename(@companyName,'''') + ' ) as matchpct' +
				' FROM ' + 
				'donnie_test.dbo.COMPANY' +
			  ' WHERE ' +
			  ' dbo.Levenshtein_pct(name, ' +   quotename(@companyName,'''') + ' ) > ' + QUOTENAME(@cnt,'''') + ' )
	  insert into donnie_test.dbo.Lev_matchkeys (co_id, name, name_noltd,cs_id, custco, custname,matchpct)
	select co_id, name, name_noltd,cs_id, custco, custname,matchpct FROM cte'
			  
			   
  EXEC sp_executeSQL @sql
  
  

  --set @cnt = @cnt - 5

END

close cursorNullcoid
deallocate cursorNullcoid

--ROLLBACK TRANSACTION
COMMIT TRANSACTION