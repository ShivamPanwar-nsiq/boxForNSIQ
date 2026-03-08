const files = [];
const listeners = new Set();

export function addFiles(newFiles){

    let addedCount = 0;
    let duplicateCount = 0;

    newFiles.forEach(file => {

        const exists = files.some(existing => existing.id === file.id);

        if(!exists){
            files.push(file);
            addedCount++;
        } 
        else{
            duplicateCount++;
        }

    });

    if(addedCount > 0){
        notifyListeners();
    }

    return {
        added: addedCount,
        duplicates: duplicateCount
    };

}

export function getFiles(){
    return [...files];
}

export function registerListener(listener){
    listeners.add(listener);
}

export function unregisterListener(listener){
    listeners.delete(listener);
}

function notifyListeners(){

    const snapshot = [...files];

    listeners.forEach(listener=>{
        listener(snapshot);
    });

}