public class OpportunityProductHandler extends TriggerHandler {
    public override void beforeInsert() {
        for (OpportunityLineItem oli : (List<OpportunityLineItem>) Trigger.new) {
            oli.Quantity = 1;
        }
    }
    public override void beforeUpdate() {
        for (OpportunityLineItem oli : (List<OpportunityLineItem>) Trigger.new) {
           OpportunityLineItem oldOli = (OpportunityLineItem) Trigger.oldMap.get(oli.Id);
            if (oli.Quantity != oldOli.Quantity) {
                oli.addError('Quantity must be equal to 1.');
            }
        }
    }
}