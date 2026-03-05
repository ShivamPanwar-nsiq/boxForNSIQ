import { LightningElement, track } from 'lwc';
import getBoxItems from '@salesforce/apex/BoxController.getBoxItems';
import { addFiles } from 'c/boxFileStore';

export default class AddFileComponent extends LightningElement {

    @track items = [];

    folderId = '0';
    folderStack = [];
    currentFolderName = 'Box Folders';

    selectedMap = {};

    connectedCallback(){
        this.loadItems();
    }

    get cardTitle(){
        return this.currentFolderName;
    }

    get showBackButton(){
        return this.folderStack.length > 0;
    }

    get showAddButton(){
        return Object.keys(this.selectedMap).length > 0;
    }

    loadItems(){

        getBoxItems({ folderId: this.folderId })
        .then(result => {

            let data = result.map(item => ({
                ...item,
                rowId: item.id,
                parentFolderId:null,
                indent:'',
                checked: !!this.selectedMap[item.id],
                sizeDisplay:item.size || '-',
                modifiedDisplay:item.modified || '-',
                isFolder:item.type === 'folder',
                isFile:item.type === 'file'
            }));

            if(this.folderId === '0'){
                data = data.filter(i => i.isFolder);
                this.currentFolderName = 'Box Folders';
            }

            this.items = data;

        });

    }

    handleCheckbox(event){

        const id = event.target.dataset.id;
        const type = event.target.dataset.type;
        const checked = event.target.checked;

        if(type === 'folder'){

            if(checked){

                this.selectedMap[id] = true;

                getBoxItems({ folderId:id })
                .then(result => {

                    const files = result
                    .filter(i => i.type === 'file')
                    .map(file => {

                        this.selectedMap[file.id] = true;

                        return {
                            ...file,
                            rowId:id+'-'+file.id,
                            parentFolderId:id,
                            indent:'padding-left:25px',
                            checked:true,
                            sizeDisplay:file.size || '-',
                            modifiedDisplay:file.modified || '-',
                            isFolder:false,
                            isFile:true
                        };

                    });

                    const index = this.items.findIndex(i => i.id === id);

                    this.items = [
                        ...this.items.slice(0,index+1),
                        ...files,
                        ...this.items.slice(index+1)
                    ];

                    this.items = this.items.map(item=>{
                        if(item.id === id){
                            return {...item,checked:true};
                        }
                        return item;
                    });

                });

            }
            else{

                delete this.selectedMap[id];

                this.items = this.items.filter(item => {

                    if(item.parentFolderId === id){
                        delete this.selectedMap[item.id];
                        return false;
                    }

                    return true;

                });

                this.items = this.items.map(item=>{
                    if(item.id === id){
                        return {...item,checked:false};
                    }
                    return item;
                });

            }

        }

        if(type === 'file'){

            if(checked){
                this.selectedMap[id] = true;
            }
            else{
                delete this.selectedMap[id];
            }

            const row = this.items.find(i => i.id === id);
            const parentId = row.parentFolderId;

            if(parentId){

                const folderFiles = this.items.filter(
                    i => i.parentFolderId === parentId
                );

                const anyChecked = folderFiles.some(
                    f => this.selectedMap[f.id]
                );

                this.items = this.items.map(item => {

                    if(item.id === id){
                        return {...item,checked:checked};
                    }

                    if(item.id === parentId){
                        return {...item,checked:anyChecked};
                    }

                    return item;

                });

                if(anyChecked){
                    this.selectedMap[parentId] = true;
                }
                else{
                    delete this.selectedMap[parentId];
                }

            }

        }

    }

    handleClick(event){

        const row = event.currentTarget.parentElement;

        const id = row.dataset.id;
        const type = row.dataset.type;
        const name = row.dataset.name;
        const url = row.dataset.url;

        if(type === 'folder'){

            this.folderStack.push({
                id:this.folderId,
                name:this.currentFolderName
            });

            this.folderId = id;
            this.currentFolderName = name;

            this.loadItems();

        }

        if(type === 'file'){
            window.open(url,'_blank');
        }

    }

    goBack(){

        if(this.folderStack.length > 0){

            const prev = this.folderStack.pop();

            this.folderId = prev.id;
            this.currentFolderName = prev.name;

            this.loadItems();

        }

    }

    handleAddToSalesforce(){

        const selectedFiles = this.items
        .filter(i => i.isFile && this.selectedMap[i.id])
        .map(i => ({
            id:i.id,
            name:i.name,
            url:i.url,
            size:i.sizeDisplay,
            modified:i.modifiedDisplay
        }));

        addFiles(selectedFiles);

        this.selectedMap = {};

        this.items = this.items.map(i=>{
            return {...i,checked:false};
        });

    }

}