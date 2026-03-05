// Global store for Box files

const files = [];
const listeners = new Set();

export function addFiles(newFiles){

    let addedCount = 0;
    let duplicateCount = 0;

    newFiles.forEach(file => {

        const exists = files.some(existingFile => existingFile.id === file.id);

        if(!exists){
            files.push(file);
            addedCount++;
        }else{
            duplicateCount++;
        }

    });

    notifyListeners();

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

function notifyListeners(){

    listeners.forEach(listener => {
        listener([...files]);
    });

}