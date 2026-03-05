// Global store for Box files

const files = [];
const listeners = new Set();

export function addFiles(newFiles){

    newFiles.forEach(file => {
        files.push(file);
    });

    notifyListeners();

}

export function getFiles(){
    return files;
}

export function registerListener(listener){
    listeners.add(listener);
}

function notifyListeners(){

    listeners.forEach(listener => {
        listener([...files]);
    });

}