USE [piHIRE1.0_QA]
GO

CREATE OR ALTER PROCEDURE [dbo].[Sp_Suggest_Job_Candidate_List_Count]

	@SearchKey nvarchar(max),

	@Recruiter nvarchar(256),--Array
	@Rating nvarchar(256),--Array
	@ApplicationStatus nvarchar(256),--Array
	@Gender nvarchar(256),--Array
	@Nationality nvarchar(max),--Array
	@CurrentLocation nvarchar(max),--Array
	@Source nvarchar(256),--Array,
	@MaritalStatus nvarchar(256),--Array,

	@Currency nvarchar(256),
	@Availability int,
	@MinAge int,
	@MaxAge int,

	@SalaryMinRange int,
	@SalaryMaxRange int,

	@JobId int

AS
begin

	declare @tblTechs table(id int)
	insert @tblTechs
	select distinct TechnologyID from [dbo].[PH_JOB_OPENING_SKILLS] where [Status] = 1 and JOID = @JobId;

	declare @SkilCount int;
	select @SkilCount = count(1) from @tblTechs

	--declare @JobSKills nvarchar(max);	
	--SELECT @JobSkills = COALESCE(STUFF((SELECT ', ' + CAST(TechnologyID AS nvarchar(max)) 
	--									   FROM [dbo].[PH_JOB_OPENING_SKILLS] 
	--									   WHERE JoId = @JobId 
	--									   FOR XML PATH('')), 1, 2, ''), '');

	--SELECT @SkilCount = COUNT(TechnologyID) FROM [dbo].[PH_JOB_OPENING_SKILLS] WHERE JoId = @JobId;

	--declare @CanIds nvarchar(max);
	--SELECT @CanIds = COALESCE(STUFF((SELECT ', ' + CAST(CandProfID AS nvarchar(max)) 
	--								   FROM [dbo].[PH_JOB_CANDIDATES] 
	--								   WHERE JoId = @JobId 
	--								   FOR XML PATH('')), 1, 2, ''), '');
	declare @tblJobCands table(id int)
	insert @tblJobCands
	select CandProfID  FROM [dbo].[PH_JOB_CANDIDATES] where [Status] != 5 and JoId = @JobId;


	select Count(CandProfID) as CandidateCount from [dbo].PH_CANDIDATE_PROFILES as CANDIDATE_PROFILE join (
		select * from (
			select *, row_number() over (
				partition by CandProfID
				order by CreatedDate desc
			) as row_num
			from [dbo].PH_JOB_CANDIDATES where CandProfID not in (SELECT id from @tblJobCands)
		) as ordered_widgets
		where ordered_widgets.row_num = 1
	) as JOB_CANDIDATES
	on CANDIDATE_PROFILE.ID = JOB_CANDIDATES.CandProfID

	join [dbo].PH_CAND_STATUS_S as CAND_STATUS_S  WITH(NOLOCK) on JOB_CANDIDATES.CandProfStatus  = CAND_STATUS_S.Id
	left join [dbo].PI_HIRE_USERS as RecUser on JOB_CANDIDATES.RecruiterID = RecUser.Id
	left join [dbo].PH_COUNTRY as Cuntry  WITH(NOLOCK) on CANDIDATE_PROFILE.CountryID = Cuntry.Id 

	where  
		CANDIDATE_PROFILE.ID in (
				   Select CAND_PROFILE.ID from [dbo].PH_CANDIDATE_PROFILES as CAND_PROFILE
					 inner join (select Count(Skill.TechnologyId)/@SkilCount as skillAvg, skill.CandProfID
							  from [dbo].[PH_CANDIDATE_SKILLSET] as Skill  WITH(NOLOCK)
							  where skill.TechnologyId in (SELECT id from @tblTechs)
							   GROUP BY skill.CandProfID
			) machSk  on  machSk.CandProfID = CAND_PROFILE.ID
			where  machSk.skillAvg >= 0.7) 

	and (@ApplicationStatus is null or JOB_CANDIDATES.CandProfStatus in (SELECT value from string_split(@ApplicationStatus, ','))) 
	and (@Gender is null or Gender in (SELECT cast(value as int) from string_split(@Gender, ','))) 
	and (@Source is null or SourceID in (SELECT value from string_split(@Source, ','))) 
	and (@CurrentLocation is null or CurrLocationID in (SELECT value from string_split(@CurrentLocation, ','))) 
	and (@Nationality is null or CANDIDATE_PROFILE.CountryID in (SELECT cast(value as int) from string_split(@Nationality, ',')))
	and (@Recruiter is null or RecruiterId in (SELECT value from string_split(@Recruiter, ','))) 
	and (@Availability is null or NoticePeriod <= @Availability) 

	and (@SearchKey is null or (CANDIDATE_PROFILE.ContactNo like '%'+@SearchKey or CANDIDATE_PROFILE.EmailID like '%'+@SearchKey 
		or CANDIDATE_PROFILE.CandName like '%'+@SearchKey
	))

	and (@Currency is null or OpCurrency like '%'+@Currency) 
	and (@SalaryMinRange is null or OpGrossPayPerMonth BETWEEN @SalaryMinRange and @SalaryMaxRange) 
	and (@MinAge is null or datediff(year, CANDIDATE_PROFILE.DOB, getdate())  BETWEEN @MinAge and @MaxAge)  
	and (@MaritalStatus is null or MaritalStatus in (SELECT cast(value as int) from string_split(@MaritalStatus, ','))) 

end
Go

CREATE OR ALTER PROCEDURE [dbo].[Sp_Suggest_Job_Candidate_List]

	@SearchKey nvarchar(max),

	@Recruiter nvarchar(256),--Array
	@Rating nvarchar(256),--Array
	@ApplicationStatus nvarchar(256),--Array
	@Gender nvarchar(256),--Array
	@Nationality nvarchar(max),--Array
	@CurrentLocation nvarchar(max),--Array
	@Source nvarchar(256),--Array,
	@MaritalStatus nvarchar(256),--Array,

	@Currency nvarchar(256),
	@Availability int,
	@MinAge int,
	@MaxAge int,

	@SalaryMinRange int,
	@SalaryMaxRange int,

	@JobId int,

	@PerPage int,
	@CurrentPage int

AS
begin

	declare @tblTechs table(id int)
	insert @tblTechs
	select distinct TechnologyID from [dbo].[PH_JOB_OPENING_SKILLS] where [Status] = 1 and JOID = @JobId;

	declare @SkilCount int;
	select @SkilCount = count(1) from @tblTechs

	--declare @JobSKills nvarchar(max);	
	--declare @CanIds nvarchar(max);
	--declare @SkilCount int;

	--SELECT @JobSkills = COALESCE(STUFF((SELECT ', ' + CAST(TechnologyID AS nvarchar(max)) 
	--									   FROM [dbo].[PH_JOB_OPENING_SKILLS] 
	--									   WHERE JoId = @JobId 
	--									   FOR XML PATH('')), 1, 2, ''), '');

	--SELECT @SkilCount = COUNT(TechnologyID) FROM [dbo].[PH_JOB_OPENING_SKILLS] WHERE JoId = @JobId;

	--SELECT @CanIds = COALESCE(STUFF((SELECT ', ' + CAST(CandProfID AS nvarchar(max)) 
	--								   FROM [dbo].[PH_JOB_CANDIDATES] 
	--								   WHERE JoId = @JobId 
	--								   FOR XML PATH('')), 1, 2, ''), '');
	declare @tblJobCands table(id int)
	insert @tblJobCands
	select CandProfID  FROM [dbo].[PH_JOB_CANDIDATES] where [Status] != 5 and JoId = @JobId;


	select 
		JOB_CANDIDATES.JoId,JOB_CANDIDATES.CandProfID,SourceID, CANDIDATE_PROFILE.EmailID, CandName, FullNameInPP,
		CANDIDATE_PROFILE.DOB, 
		(select RMValue from dbo.PH_REF_MASTER_S where id = CANDIDATE_PROFILE.Gender) AS Gender, 
		(select RMValue from dbo.PH_REF_MASTER_S where id = CANDIDATE_PROFILE.MaritalStatus) AS MaritalStatus,

		JOB_CANDIDATES.CandProfStatus,CAND_STATUS_S.title AS CandProfStatusName,

		(select STUFF((select ','+ TaggingWord from [dbo].[PH_CANDIDATE_TAGS] as Tags  WITH(NOLOCK)
		 where Tags.JOID = JOB_CANDIDATES.JOID and Tags.CandProfID =JOB_CANDIDATES.CandProfID  
		 and Status !=5  for xml path('')),1,1,'')) as TagWords,
 
		JOB_CANDIDATES.StageID,CAND_STATUS_S.CsCode,
		CurrOrganization,  CurrLocation, CurrLocationID, NoticePeriod, 
		CANDIDATE_PROFILE.CountryID,Cuntry.nicename as CountryName,
		ReasonType, ReasonsForReloc,
		(select nicename from dbo.PH_COUNTRY where id = CANDIDATE_PROFILE.Nationality) AS Nationality,
		Experience, ExperienceInMonths, RelevantExperience, 
		ReleExpeInMonths, ContactNo, AlteContactNo,RecruiterId,
		CONCAT(RecUser.FirstName,' ',RecUser.LastName) as RecName,
		CPCurrency,CPTakeHomeSalPerMonth,CPGrossPayPerAnnum,
		JOB_CANDIDATES.EPCurrency as EPCurrency,JOB_CANDIDATES.EPTakeHomePerMonth as EPTakeHomePerMonth,
		JOB_CANDIDATES.OpCurrency as OpCurrency,JOB_CANDIDATES.OpGrossPayPerMonth as OpTakeHomePerMonth,

		(select Convert(decimal(10,2),SUM(pjc.SelfRating)/Count(*)) from [dbo].PH_JOB_CANDIDATES as pjc
		where pjc.CandProfId = CANDIDATE_PROFILE.ID) as SelfRating,

		(select Convert(decimal(10,2),SUM(pjce.Rating)/Count(*)) from [dbo].PH_JOB_CANDIDATE_EVALUATION as pjce
		where  pjce.JoId = JOB_CANDIDATES.JoId and pjce.CandProfId = JOB_CANDIDATES.CandProfID) as Evaluation,


		CANDIDATE_PROFILE.CreatedDate,JOB_CANDIDATES.UpdatedDate,null as JobCategory,TLReview,MReview 
	
	from 
		[dbo].PH_CANDIDATE_PROFILES as CANDIDATE_PROFILE 
		join (
			select * from (
				select *, row_number() over (
					partition by CandProfID
					order by CreatedDate desc
				) as row_num
				from [dbo].PH_JOB_CANDIDATES where CandProfID not in (SELECT id from @tblJobCands)
			) as ordered_widgets
			where ordered_widgets.row_num = 1
		) as JOB_CANDIDATES
		on CANDIDATE_PROFILE.ID = JOB_CANDIDATES.CandProfID

		join [dbo].PH_CAND_STATUS_S as CAND_STATUS_S  WITH(NOLOCK) on JOB_CANDIDATES.CandProfStatus  = CAND_STATUS_S.Id
		left join [dbo].PI_HIRE_USERS as RecUser on JOB_CANDIDATES.RecruiterID = RecUser.Id
		left join [dbo].PH_COUNTRY as Cuntry  WITH(NOLOCK) on CANDIDATE_PROFILE.CountryID = Cuntry.Id 

	where  
		CANDIDATE_PROFILE.ID in (
			   Select CAND_PROFILE.ID from [dbo].PH_CANDIDATE_PROFILES as CAND_PROFILE
				 inner join (select Count(Skill.TechnologyId)/@SkilCount as skillAvg, skill.CandProfID
						  from [dbo].[PH_CANDIDATE_SKILLSET] as Skill  WITH(NOLOCK)
						  where skill.TechnologyId in (SELECT id from @tblTechs)
						   GROUP BY skill.CandProfID
			) machSk  on  machSk.CandProfID = CAND_PROFILE.ID
			where  machSk.skillAvg >= 0.7) 

		and (@ApplicationStatus is null or JOB_CANDIDATES.CandProfStatus in (SELECT value from string_split(@ApplicationStatus, ','))) 
		and (@Gender is null or Gender in (SELECT cast(value as int) from string_split(@Gender, ','))) 
		and (@Source is null or SourceID in (SELECT value from string_split(@Source, ','))) 
		and (@CurrentLocation is null or CurrLocationID in (SELECT value from string_split(@CurrentLocation, ','))) 
		and (@Nationality is null or CANDIDATE_PROFILE.CountryID in (SELECT cast(value as int) from string_split(@Nationality, ',')))
		and (@Recruiter is null or RecruiterId in (SELECT value from string_split(@Recruiter, ','))) 
		and (@Availability is null or NoticePeriod <= @Availability) 

		and (@SearchKey is null or (CANDIDATE_PROFILE.ContactNo like '%'+@SearchKey or CANDIDATE_PROFILE.EmailID like '%'+@SearchKey 
			or CANDIDATE_PROFILE.CandName like '%'+@SearchKey
		))

		and (@Currency is null or OpCurrency like '%'+@Currency) 
		and (@SalaryMinRange is null or OpGrossPayPerMonth BETWEEN @SalaryMinRange and @SalaryMaxRange) 
		and (@MinAge is null or datediff(year, CANDIDATE_PROFILE.DOB, getdate())  BETWEEN @MinAge and @MaxAge)  
		and (@MaritalStatus is null or MaritalStatus in (SELECT cast(value as int) from string_split(@MaritalStatus, ','))) 

	Order by 
		SelfRating desc offset @CurrentPage rows fetch next @PerPage rows only;


end
