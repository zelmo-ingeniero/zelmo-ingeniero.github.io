function copyToClipboard(input_tag) {
  navigator.clipboard.writeText(input_tag.value);
  const message =
    "<i class=" +
    "'fa-solid fa-circle-check px-2 my-auto align-middle text-green-400'" +
    "></i><p class=" +
    "'p-2'" +
    ">Copied to clipboard</p>";
  showToast(message);
}
function showToast(text) {
  let toast = document.getElementById("toast");
  toast.innerHTML = text;
  toast.classList.add("animate-fade-in");
  setTimeout(() => {
    toast.classList.add("animate-fade-out");
    setTimeout(() => {      
      toast.classList.remove("animate-fade-in");
      toast.classList.remove("animate-fade-out");
      toast.innerHTML = "";
    }, 500);
  }, 2000);
}
