USE [piHIRE1.0_QA]
GO

CREATE OR ALTER PROCEDURE [dbo].[Sp_Candidate_List]

    @SearchKey nvarchar(max),
    @Rating nvarchar(256),--Array
    @ApplicationStatus nvarchar(256),--Array
    @Gender nvarchar(256),--Array
    @Nationality nvarchar(max),--Array
    @CurrentLocation nvarchar(max),--Array
    @Recruiter nvarchar(max), --Array
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
	@toDate datetime,

    @PerPage int,
    @CurrentPage int

AS
BEGIN
	declare @SearchKeyLike nvarchar(max) = '%'+coalesce(@SearchKey,'')+'%';

   
        SELECT 
            JoId, CandProfID, SourceID, EmailID, CandName, FullNameInPP, DOB, 
			(select RMValue from dbo.PH_REF_MASTER_S where id = Gender) AS Gender, 
			(select RMValue from dbo.PH_REF_MASTER_S where id = MaritalStatus) AS MaritalStatus,

            CandProfStatus, CandProfStatusName, TagWords, StageID, CsCode, CurrOrganization, CurrLocation,
            CurrLocationID, NoticePeriod, CountryID, CountryName, ReasonType, ReasonsForReloc, 
			(select nicename from dbo.PH_COUNTRY where id = Nationality) AS Nationality, 
			Experience,
            ExperienceInMonths, RelevantExperience, ReleExpeInMonths, ContactNo, AlteContactNo, RecruiterId, RecName,
            CPCurrency, CPTakeHomeSalPerMonth, CPGrossPayPerAnnum, EPCurrency, EPTakeHomePerMonth,
            OpCurrency, OpTakeHomePerMonth, SelfRating, Evaluation, PuId, JobCategory,
            CreatedDate, UpdatedDate
        FROM [dbo].[vwAllCandidates]
        WHERE (1 = 1)
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
          --  AND (@MinAge IS NULL OR DATEDIFF(YEAR, DOB, GETDATE()) BETWEEN @MinAge AND @MaxAge)
            AND (@MaritalStatus IS NULL OR MaritalStatus IN (SELECT cast(value as int) FROM string_split(@MaritalStatus, ',')))
			AND (@fromDate IS NULL OR CreatedDate BETWEEN @fromDate AND @toDate)
          --   AND (@Rating IS NULL OR CAST(SelfRating AS INT) IN (SELECT CAST(value AS INT) FROM string_split(@Rating, ',')))
    
     
   ORDER BY CandProfID DESC
		OFFSET @CurrentPage ROWS FETCH NEXT @PerPage ROWS ONLY;

   
END



