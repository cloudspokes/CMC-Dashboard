public with sharing class CMC_DashboardController extends CMC_DashboardControllerBase {
	
	public CMC_DashboardController() {
		super();
	}
	
	override public PageReference reloadPageByType() {
		PageReference page = getCleanPageWithTypeAccount();
		return doForward(page);
	}
	
	override public PageReference reloadPageByAccount() {
		PageReference page = getCleanCurrentPage();
		
		page.getParameters().put('type', selectItem);
		page.getParameters().put('account', selectAccountId);
		return doForward(page);
	}
	
	override public boolean getRenderLink() {
		return false;
	}
	
	public boolean getRenderMetrics() {
		if(selectItem==null) return false;
		if(selectItem.equals(METRICS))
			return true;
		else
			return false;
	}
	
	public boolean getRenderGoogleMetrics() {
		if(selectItem==null) return false;
		if(selectItem.equals(GOOGLE_METRICS))
			return true;
		else
			return false;
	}
	
	public boolean getRenderProjectTracker() {
		if(selectItem==null) return false;
		if(selectItem.equals(PROJECT_TRACKER))
			return true;
		else
			return false;
	}
	
	public boolean getRenderAccountPickList() {
		if(selectItem==null) return false;
		system.debug('<<======>>> Determining whether to display Account picklist or not');
		boolean retvalue;
		retvalue = false;
		/**Added by rohit* Rohit [9/16/2011]*/
		// If user is not customer and account option != null show Account picklist
		if(!CMC_UserType.isUserTypeCustomer(UserInfo.getProfileId()) && accountOptions != null && accountOptions.size()>1){
			retvalue = true;
		}
		
		return retvalue;
	}
	
	public boolean getRenderMonitor() {
		if(selectItem==null) return false;
		if(selectItem.equals(MONITOR))
			return true;
		else
			return false;
	}
	
	public boolean getRenderMyTasks() {
		if(selectItem==null) return false;
		if(selectItem.equals(MY_TASKS))
			return true;
		else
			return false;
	}
	
	public boolean getRenderAccount() {
		if(selectItem==null) return false;
		List<AggregateResult> groupedResults;
		if(selectItem.equals(PROJECT_TRACKER)) {
			groupedResults = [select Account__c from CMC_Product__c group by Account__c];
		} else {
			//Metrics or Monitor selected
			groupedResults = [select Account_Id__c from CMC_Connection__c group by Account_Id__c];
		}
		if(groupedResults != null && groupedResults.size() > 1) {
			return true;
		} else {
			return false;
		}
	}
}