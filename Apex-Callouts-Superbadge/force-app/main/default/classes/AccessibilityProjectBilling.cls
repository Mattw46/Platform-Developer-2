global class AccessibilityProjectBilling{
    
     @future(callout=true)
     public static void callBillingService(String projectId, Decimal billingAmount){
          BillingServiceProxy.project project = new BillingServiceProxy.project();
          project.username = '{!$Credential.BillingServiceCredential.Username}';
          project.password = '{!$Credential.BillingServiceCredential.Password}';
          project.projectid = projectId;
          project.billAmount = Double.valueOf(billingAmount);

          BillingServiceProxy.InvoicesPortSoap11 port = new BillingServiceProxy.InvoicesPortSoap11();
          String response = port.billProject(project);

          if (response != null && response.equalsIgnoreCase('OK')) {
               Accessibility_Project__c accessibilityProject = [
                    SELECT Id, Status__c
                    FROM Accessibility_Project__c
                    WHERE Id = :projectId
                    LIMIT 1
               ];
               accessibilityProject.Status__c = 'Complete';
               update accessibilityProject;
          }
     }
}