import { LightningElement } from 'lwc';
export default class MyComponent extends LightningElement {
    greeting = 'Hello World';
    
    handleClick() {
        this.greeting = 'Hello Lightning!';
    }
}