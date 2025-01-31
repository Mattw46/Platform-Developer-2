public class AddPrimaryContact implements Queueable {
    Contact contact;
    String state;

    public AddPrimaryContact(Contact contact, String state) {
        this.contact = contact;
        this.state = state;
    }

    public void execute(QueueableContext context) {
        List<Account> accounts = [SELECT Id, BillingState FROM Account WHERE BillingState =: state LIMIT 200];
        List<Contact> contacts = new List<Contact>();
        for (Account account : accounts) {
            Contact contact = contact.clone();
            contact.AccountId = account.Id;
            contacts.add(contact);
        }
        insert contacts;
    }
}