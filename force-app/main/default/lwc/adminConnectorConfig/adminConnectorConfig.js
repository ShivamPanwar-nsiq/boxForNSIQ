import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getConnectorConfigs from '@salesforce/apex/ConnectorAdminService.getConnectorConfigs';
import saveSharedCredential from '@salesforce/apex/ConnectorAdminService.saveSharedCredential';
import { refreshApex } from '@salesforce/apex';

const EMPTY_FORM = {
    connectorDeveloperName: '',
    clientId: '',
    clientSecret: ''
};

export default class AdminConnectorConfig extends LightningElement {
    @track form = { ...EMPTY_FORM };
    configs = [];
    wiredConfigsResult;

    columns = [
        { label: 'Connector', fieldName: 'label' },
        { label: 'Client ID', fieldName: 'sharedClientId' },
        { label: 'Configured', fieldName: 'hasSharedCredential', type: 'boolean' },
        { type: 'button', typeAttributes: { label: 'Load', name: 'load', variant: 'base' } }
    ];

    @wire(getConnectorConfigs)
    wiredConfigs(result) {
        this.wiredConfigsResult = result;
        if (result.data) {
            this.configs = result.data;
            if (!this.form.connectorDeveloperName && result.data.length) {
                this.form = { ...this.form, connectorDeveloperName: result.data[0].developerName };
            }
        } else if (result.error) {
            this.showError(result.error);
        }
    }

    get connectorOptions() {
        return this.configs.map((connector) => ({ label: connector.label, value: connector.developerName }));
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this.form = { ...this.form, [field]: event.target.value };
    }

    handleRowAction(event) {
        const row = event.detail.row;
        this.form = {
            ...EMPTY_FORM,
            connectorDeveloperName: row.developerName,
            clientId: row.sharedClientId || ''
        };
    }

    async saveCredential() {
        try {
            console.log('this.form : ', JSON.stringify(this.form));
            await saveSharedCredential({ input: this.form });
            this.dispatchEvent(new ShowToastEvent({ title: 'Saved', message: 'Shared OAuth credentials saved.', variant: 'success' }));
            this.resetForm();
            await refreshApex(this.wiredConfigsResult);
        } catch (error) {
            this.showError(error);
        }
    }

    resetForm() {
        this.form = {
            ...EMPTY_FORM,
            connectorDeveloperName: this.configs.length ? this.configs[0].developerName : ''
        };
    }

    showError(error) {
        const message = error?.body?.message || error?.message || 'Unexpected error';
        this.dispatchEvent(new ShowToastEvent({ title: 'Error', message, variant: 'error' }));
    }
}