import { LightningElement } from 'lwc';
import getBoxLoginUrl from '@salesforce/apex/BoxAuthController.getBoxLoginUrl';

export default class BoxAuth extends LightningElement {

connectBox(){

getBoxLoginUrl()
.then(url => {

window.open(
url,
"BoxLogin",
"width=600,height=700"
);

})
.catch(error=>{
console.error('Error getting login URL', error);
});

}

connectedCallback(){

window.addEventListener("message", (event)=>{

if(event.data && event.data.type === "BOX_AUTH"){

const authCode = event.data.code;

console.log("Authorization Code:", authCode);

// Next step: send code to Apex to get access token

}

});

}

}