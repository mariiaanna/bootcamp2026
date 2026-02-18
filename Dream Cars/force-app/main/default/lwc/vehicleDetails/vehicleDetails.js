import { LightningElement, api } from 'lwc';

export default class VehicleDetails extends LightningElement {
    @api vehicle;
    @api errorMessage;
}