import { LightningElement, track } from 'lwc';
import getAllVehicles from '@salesforce/apex/SmartCarService.getAllVehicles';
import getFullVehicleDetails from '@salesforce/apex/SmartCarService.getFullVehicleDetails';

export default class SmartCarContainer extends LightningElement {
    @track vehicles = [];
    @track selectedVehicle;
    @track errorMessage;
    isLoading = false;

    handleGetAllVehicles() {
        this.isLoading = true;
        this.errorMessage = '';
        getAllVehicles()
            .then(result => {
                this.vehicles = result;
                this.selectedVehicle = null; 
            })
            .catch(error => {
                this.errorMessage = 'Error: ' + error.body.message;
            })
            .finally(() => { this.isLoading = false; });
    }

    handleVehicleSelect(event) {
        const vehicleId = event.detail;
        this.isLoading = true;
        this.errorMessage = '';

        getFullVehicleDetails({ vehicleId: vehicleId })
            .then(result => {
                this.selectedVehicle = result;
            })
            .catch(error => {
                this.errorMessage = 'Error getting vehicle details: ' + error.body.message;
            })
            .finally(() => { this.isLoading = false; });
    }
}