function copyToClipboard(input_tag) {
  navigator.clipboard.writeText(input_tag.value);
  showToast("<p>Copied " + input_tag.value + " to clipboard</p>");
  console.log("toast showed")
}
function showToast(text){
    let toast_box = document.getElementById("toast-box");
    toast_box.innerHTML = "";
    let toast = document.createElement("div");
    toast.classList.add("p-4");
    toast.classList.add("text-sm");
    toast.classList.add("rounded-1");
    toast.innerHTML = text;
    toast_box.appendChild(toast);
}