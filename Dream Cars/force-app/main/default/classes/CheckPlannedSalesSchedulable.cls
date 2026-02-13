public class CheckPlannedSalesSchedulable implements Schedulable {

    public void execute(SchedulableContext ctx) {
        CheckPlannedSalesBatch batch = new CheckPlannedSalesBatch();
        Database.executeBatch(batch);
    }
}