public class CheckPlannedSalesQueueable implements Queueable {
    private List<Planned_Sales__c> recordsToNotify;
    public CheckPlannedSalesQueueable(List<Planned_Sales__c> plannedSales) {
        this.recordsToNotify = plannedSales;
    }

    public void execute(QueueableContext context) {
        List<User> admins = [SELECT Email FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true];
        List<String> adminEmails = new List<String>();
        for (User u : admins) {
            adminEmails.add(u.Email);
        }

        if (adminEmails.isEmpty()) return;

        String htmlBody = '<h1>Underperforming Sales Report</h1>';
        htmlBody += '<table border="1" style="border-collapse: collapse;">';
        htmlBody += '<tr><th>Record Name</th><th>Planned Amount</th><th>Earned Amount</th></tr>';

        for (Planned_Sales__c ps : recordsToNotify) {
            htmlBody += '<tr>';
            htmlBody += '<td>' + ps.Name + '</td>';
            htmlBody += '<td>' + ps.Planned_Total_Amount__c + '</td>';
            htmlBody += '<td>' + ps.Total_Amount_Earned__c + '</td>';
            htmlBody += '</tr>';
        }
        htmlBody += '</table>';

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(adminEmails);
        mail.setSubject('Monthly Underperforming Sales Notification');
        mail.setHtmlBody(htmlBody);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }
}