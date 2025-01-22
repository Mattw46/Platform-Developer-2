trigger OrderEventTrigger on Order_Event__e (after insert) {
   List<Task> taskList = new List<Task>();
   for (Order_Event__e oe : Trigger.new) {
       if (oe.Has_Shipped__c == true) {
           Task t = new Task(
               Priority = 'Medium',
               Subject = 'Follow up on shipped order 105',
               OwnerId = oe.CreatedById
           );
           taskList.add(t);
       }
   }
   insert taskList;
}