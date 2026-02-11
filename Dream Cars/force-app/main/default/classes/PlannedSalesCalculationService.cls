public class PlannedSalesCalculationService {
    public static void getSalesData(List<Planned_Sales__c> plannedSalesList) {
        if (plannedSalesList == null || plannedSalesList.isEmpty()) return;

        for (Planned_Sales__c ps : plannedSalesList) {
            ps.Count_of_Cars_Sold__c = 0;
            ps.Total_Amount_Earned__c = 0;
        }

        Set<Integer> years = new Set<Integer>();
        Set<Integer> months = new Set<Integer>();
        Set<String> carTypes = new Set<String>();

        for (Planned_Sales__c ps : plannedSalesList) {
            if (ps.Year__c != null) years.add(ps.Year__c.intValue());
            if (ps.Month__c != null) months.add(ps.Month__c.intValue());
            if (ps.Car_Type__c != null) carTypes.add(ps.Car_Type__c);
        }

        List<AggregateResult> results = [SELECT 
                                            CALENDAR_MONTH(Opportunity.CloseDate) mnth, 
                                            CALENDAR_YEAR(Opportunity.CloseDate) yr, 
                                            Product2.Condition__c tp, 
                                            SUM(TotalPrice) totalAmount, 
                                            COUNT(Id) totalDeals 
                                        FROM OpportunityLineItem
                                        WHERE Opportunity.StageName = 'Closed Won' 
                                        AND Product2.Condition__c IN :carTypes 
                                        AND CALENDAR_YEAR(Opportunity.CloseDate) IN :years 
                                        AND CALENDAR_MONTH(Opportunity.CloseDate) IN :months
                                        WITH USER_MODE
                                        GROUP BY CALENDAR_YEAR(Opportunity.CloseDate), 
                                                 CALENDAR_MONTH(Opportunity.CloseDate), 
                                                 Product2.Condition__c];


        Map<String, AggregateResult> resultDataMap = new Map<String, AggregateResult>();
        for (AggregateResult ar : results) {
            String key = ar.get('yr') + '-' + ar.get('mnth') + '-' + ar.get('tp');
            resultDataMap.put(key, ar);
        }

        for (Planned_Sales__c ps : plannedSalesList) {
            String key = ps.Year__c.intValue() + '-' + ps.Month__c.intValue() + '-' + ps.Car_Type__c;
            if (resultDataMap.containsKey(key)) {
                AggregateResult ar = resultDataMap.get(key);
                ps.Total_Amount_Earned__c = (Decimal)ar.get('totalAmount');
                ps.Count_of_Cars_Sold__c = (Integer)ar.get('totalDeals');
            }
        }
    }
}