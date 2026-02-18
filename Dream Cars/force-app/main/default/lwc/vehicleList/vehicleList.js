import { LightningElement, api } from 'lwc';

export default class VehicleList extends LightningElement {
    @api vehicles;
    @api errorMessage;

    handleSelect(event) {
        const vehicleId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('select', { detail: vehicleId }));
    }
}