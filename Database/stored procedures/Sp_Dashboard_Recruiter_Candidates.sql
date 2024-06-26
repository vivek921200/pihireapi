USE [piHIRE1.0_QA]
GO
Alter PROCEDURE [dbo].[Sp_Dashboard_Recruiter_Candidates]
@fmDt datetime,
@toDt datetime,
@typeId int,
--Authorization
@userType int,
@userId int 
AS
begin
	select 
		distinct vw.JobId, vw.JobTitle, vw.ClientName, vw.CandProfId, vw.CandName, vw.StatusCode, vw.ActivityDate
	from 
		[dbo].[vwJobCandidateStatusHistory] vw with(nolock)
	where 
		( 
			--(@userType = 1) or --SuperAdmin
			--(@userType = 2 and [JobId] in (select JOID from PH_JOB_OPENINGS_ADDL_DETAILS jbDtl with(nolock) inner join [dbo].[vwUserPuBu] vw on /*jbDtl.BUID=vw.[BusinessUnit] and*/ jbDtl.PUID=vw.[ProcessUnit] and vw.UserId=@userId)) or --Admin
			--(@userType = 3 and @userId = BroughtBy) or --BDM
			(@userType = 4 and vw.RecruiterId =@userId)--Recruiter 4
			--Candidate 5
		)
		and (vw.statusCode='SUC' or (@typeId=2 and vw.statusCode='PNS')) 
		and (@fmDt is null or @toDt is null or (vw.activityDate between @fmDt and @toDt))

	
end



