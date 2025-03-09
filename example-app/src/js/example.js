import { Pos } from 'pos';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    Pos.echo({ value: inputValue })
}
