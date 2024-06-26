USE [piHIRE1.0_QA]
GO

CREATE OR ALTER PROCEDURE [dbo].[Sp_Candidate_List_Count]

	@SearchKey nvarchar(max),
	@Rating nvarchar(256),--Array
	@ApplicationStatus nvarchar(256),--Array
	@Gender nvarchar(256),--Array
	@Nationality nvarchar(max),--Array
	@CurrentLocation nvarchar(max),--Array
	@Recruiter nvarchar(max),
	@Source nvarchar(256),--Array,
	@MaritalStatus nvarchar(256),--Array,

	@PuId int,
	@Currency nvarchar(256),
	@Availability int,
	@MinAge int,
	@MaxAge int,
	
	@SalaryMinRange int,
	@SalaryMaxRange int,
	@fromDate datetime,
	@toDate datetime

AS
begin
	declare @SearchKeyLike nvarchar(max) = '%'+LOWER(coalesce(@SearchKey,''))+'%';
	SELECT Count(CandJobId) as CandidateCount  FROM [dbo].[vwAllCandidates] WHERE (1 = 1)


            AND (@ApplicationStatus IS NULL OR CandProfStatus IN (SELECT value FROM string_split(@ApplicationStatus, ',')))
            AND (@Gender IS NULL OR Gender IN (SELECT cast(value as int) FROM string_split(@Gender, ',')))
            AND (@PuId IS NULL OR PuId = @PuId)
            AND (@Source IS NULL OR SourceID IN (SELECT value FROM string_split(@Source, ',')))
            AND (@CurrentLocation IS NULL OR CountryID IN (SELECT value FROM string_split(@CurrentLocation, ',')))
            AND (@Recruiter IS NULL OR RecruiterId IN (SELECT value FROM string_split(@Recruiter, ',')))
            AND (@Nationality IS NULL OR Nationality IN (SELECT cast(value as int) FROM string_split(@Nationality, ',')))
            AND (@Availability IS NULL OR NoticePeriod <= @Availability)
            AND (@SearchKey IS NULL OR (
					CandProfID LIKE @SearchKeyLike 
					OR ContactNo LIKE @SearchKeyLike 
					OR EmailID LIKE @SearchKeyLike 
					OR LOWER(CandName) LIKE @SearchKeyLike 
				))
            AND (@Currency IS NULL OR OpCurrency LIKE '%' + @Currency)
            AND (@SalaryMinRange IS NULL OR OpTakeHomePerMonth BETWEEN @SalaryMinRange AND @SalaryMaxRange)
            AND (@MinAge IS NULL OR DATEDIFF(YEAR, DOB, GETDATE()) BETWEEN @MinAge AND @MaxAge)
            AND (@MaritalStatus IS NULL OR MaritalStatus IN (SELECT cast(value as int) FROM string_split(@MaritalStatus, ',')))
            AND (@Rating IS NULL OR CAST(SelfRating AS INT) IN (SELECT CAST(value AS INT) FROM string_split(@Rating, ',')))
			AND (@fromDate IS NULL OR CreatedDate BETWEEN @fromDate AND @toDate)
end


