public class PlannedSalesCalculationService {

    public static void getSalesData(List<Planned_Sales__c> plannedSalesList) {

        Set<Integer> years = new Set<Integer>();
        Set<Integer> months = new Set<Integer>();
        Set<String> carTypes = new Set<String>();

        for (Planned_Sales__c plannedSales : plannedSalesList) {
            years.add(plannedSales.Year__c);
            months.add(plannedSales.Month__c);
            carTypes.add(plannedSales.Car_Type__c);
        }

        List<AggregateResult> result = [SELECT 
                                        MONTH(Opportunity.CloseDate) mnth, 
                                        YEAR(Opportunity.CloseDate) yr, 
                                        Product2.Condition__c tp, 
                                        SUM(TotalPrice) totalAmount, 
                                        COUNT(Id) totalDeals 
                                  FROM OpportunityLineItem 
                                  WHERE Opportunity.StageName = 'Closed Won' 
                                  AND Product2.Condition__c IN :carTypes 
                                  AND YEAR(Opportunity.CloseDate) IN :years 
                                  AND MONTH(Opportunity.CloseDate) IN :months
                                  WITH USER_MODE
                                  GROUP BY YEAR(Opportunity.CloseDate), MONTH(Opportunity.CloseDate), Product2.Condition__c];

        Map<String, AggregateResult> resultDataMap = new Map<String, AggregateResult>();
        for (AggregateResult ar : result) {
            String key = String.valueOf((Integer)ar.get('yr')) + '-' + String.valueOf((Integer)ar.get('mnth')) + '-' + (String)ar.get('tp');
            resultDataMap.put(key, ar);
        }

        for (Planned_Sales__c ps : plannedSalesList) {
            String key = String.valueOf(ps.Year__c) + '-' + String.valueOf(ps.Month__c) + '-' + ps.Car_Type__c;
            if (resultDataMap.containsKey(key)) {
                AggregateResult ar = resultDataMap.get(key);
                ps.Total_Amount_Earned__c = (Decimal)ar.get('totalAmount');
                ps.Count_of_Cars_Sold__c = (Integer)ar.get('totalDeals');
            } else {
                ps.Total_Amount_Earned__c = 0;
                ps.Count_of_Cars_Sold__c = 0;
            }
        }
    }
}