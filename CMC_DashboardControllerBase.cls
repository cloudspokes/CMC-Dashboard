abstract public with sharing class CMC_DashboardControllerBase {
    public static Integer MAX_RESULTS = 20;
    public static Integer MAX_X_LABEL = 10;
    public static String RESULT_START = '[';
    public static String RESULT_END = ']';
    public static String RESULT_SEPARATOR = ',';
    
    public static final String SCHEDULE_TYPE_SF_METRICS = 'Salesforce Metrics';
    public static final String SCHEDULE_TYPE_GOOGLE_METRICS = 'Google Metrics';
    public static final String SCHEDULE_TYPE_MONITOR_PERFORMANCE = 'Salesforce Monitor (Performance)';
    
    public static final String METRICS = 'Metrics' ;
    public static final String PROJECT_TRACKER = 'ProjectTracker' ;
    public static final String MONITOR = 'Monitor' ;
    public static final String MY_TASKS = 'My Tasks' ;
    public static final String GOOGLE_METRICS = 'Google Metrics';
    
    public String selectItem {get; set;}
    public String selectAccountId {get; set;}
    public List<SelectOption> accountOptions {get; set;}
    
    public CMC_DashboardControllerBase() {
        PageReference page = ApexPages.currentPage();
        selectItem = page.getParameters().get('type');
        if(selectItem != null) {
            initAccountOptions();
            selectAccountId = page.getParameters().get('account');
        }
    }

    public PageReference initializePage() {
        selectItem = ApexPages.currentPage().getParameters().get('type');
        //do not forward if this page has already been initialized
        if(selectItem != null) {
            return null;
        }

        //look for last saved URL, and forward if it is set
        String lastViewedUrl = [select CMC_Last_Viewed_Dashboard__c from User where Id=:UserInfo.getUserId()].CMC_Last_Viewed_Dashboard__c;
        if(lastViewedUrl!=null && lastViewedUrl.length()>0) {
            PageReference page = new PageReference(lastViewedUrl);
            Map<String, String> parameters = page.getParameters();
            for(String key : parameters.keySet()) {
                System.debug('--------- key:' + key + ' value:' + parameters.get(key));
            }
            page.setRedirect(true);
            return page;
        }
        // else, show the default page
        selectItem = 'ProjectTracker';
        return reloadPageByType();
    }
    
    // save the current forward url, and redirect the user to that page
    protected PageReference doForward(PageReference page) {
        User currentUser = [select CMC_Last_Viewed_Dashboard__c from User where Id=:UserInfo.getUserId()];
        currentUser.CMC_Last_Viewed_Dashboard__c = page.getUrl();
        update currentUser;
        
        page.setRedirect(true);
        return page;
    }
    
    abstract public PageReference reloadPageByType();
    abstract public PageReference reloadPageByAccount();
    abstract public boolean getRenderLink();
	
    protected PageReference getCleanPageWithTypeAccount() {
        PageReference page = getCleanCurrentPage();
        
        page.getParameters().put('type', selectItem);
        initAccountOptions();
        if(accountOptions.size()>0) {
            selectAccountId = accountOptions.get(0).getValue();
        } else {
            selectAccountId = '';
        }
        page.getParameters().put('account', selectAccountId);
        return page;
    }
    
    protected PageReference getCleanCurrentPage() {
        PageReference page = ApexPages.currentPage();
        //clear all parameters
        for(String param : page.getParameters().keySet()) {
            page.getParameters().put(param, null);
        }
        //setup tab name
        String tabName = [select Dashboard_Tab_Name__c from CMC_Metrics_Settings__c where Name='default'].Dashboard_Tab_Name__c;
        page.getParameters().put('sfdc.tabName', tabName);
        return page;
    }

    private boolean isValidItem(String selectItem) {
        if(selectItem.equals(PROJECT_TRACKER) ||
            selectItem.equals(METRICS) ||
            selectItem.equals(MONITOR) ||
            selectItem.equals(GOOGLE_METRICS)) {
                return true;
        }
        return false;
    }
    
    public List<SelectOption> getSelectItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(PROJECT_TRACKER,'Sprint Status'));
        options.add(new SelectOption(METRICS,'Salesforce Metrics'));
        options.add(new SelectOption(MONITOR,'Salesforce Monitor'));
        options.add(new SelectOption(MY_TASKS,'My Tasks'));
        options.add(new SelectOption(GOOGLE_METRICS,'Google Metrics'));
        return options;
    }
    
    public void initAccountOptions() {
        accountOptions = new List<SelectOption>();
        //Customer should only see their own account
        if(CMC_UserType.isUserTypeCustomer(UserInfo.getProfileId())) {
        	Account acc = [select Id, Name from Account where Id=:CMC_UserType.getCurrentUserAccountId()];
        	accountOptions.add(new SelectOption(acc.Id, acc.Name));
        } else {
	        List<AggregateResult> groupedResults = new List<AggregateResult>();
	        /* updated by Rohit */
	        if(selectItem.equals(PROJECT_TRACKER) || selectItem.equals(MY_TASKS)) {
	            groupedResults = [select Account__c acc from CMC_Product__c group by Account__c];
	        }else if (selectItem.equals(METRICS)) {
	            //Metrics selected
	            groupedResults = [select Connection_Rel__r.Account_Id__r.Id acc from CMC_Schedule__c where RecordType.Name=:SCHEDULE_TYPE_SF_METRICS group by Connection_Rel__r.Account_Id__r.Id];
	        } else if (selectItem.equals(GOOGLE_METRICS)) {
	            //Metrics selected
	            groupedResults = [select Connection_Rel__r.Account_Id__r.Id acc from CMC_Schedule__c where RecordType.Name=:SCHEDULE_TYPE_GOOGLE_METRICS group by Connection_Rel__r.Account_Id__r.Id];
	        } else {
	            //Monitor selected
	            groupedResults = [select Connection_Rel__r.Account_Id__r.Id acc from CMC_Schedule__c where RecordType.Name=:SCHEDULE_TYPE_MONITOR_PERFORMANCE group by Connection_Rel__r.Account_Id__r.Id];
	        }
	        
	        List<String> idList = new List<String>();
	        //Add user's account id to list: I-10080 (https://appirio.my.salesforce.com/a3v50000000GtCZ)
	        String currentAccountId = CMC_UserType.getCurrentUserAccountId();
	        if(currentAccountId!=null) {
		        idList.add(currentAccountId);
	        }
	        for(AggregateResult ar : groupedResults) {
	            idList.add((String)ar.get('acc'));
	        }
	        List<Account> accountList = [select Id, Name from Account where Id in :idList order by Name];
	        for(Account acc : accountList) {
	            accountOptions.add(new SelectOption(acc.Id,acc.Name));
	        }
        }
    }

    public static List<SelectOption> sortSelectOptions(List<SelectOption> items) {
    	Map<String, SelectOption> mapToSort = new Map<String, SelectOption>() ;
    	List<SelectOption> sortedOptions = new List<SelectOption>() ; 
    	for (SelectOption item : items) {
    		mapToSort.put(item.getLabel() , item) ;
    	}
    	List<String> sortedKeys = new List<String>(mapToSort.keySet()) ;
    	sortedKeys.sort() ;
    	
    	for (String sortedKey : sortedKeys) {
    	 sortedOptions.add(mapToSort.get(sortedKey)) ;
    	}
    	return sortedOptions ; 
    }
    
}