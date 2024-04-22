function copyToClipboard(text) {
  const message =
    "<i class='fa-solid fa-circle-check px-2 my-auto align-middle text-green-400'></i>" +
    "<p class='p-2'>" +
    "Copied to clipboard</p>";
  console.log("disabled jeje");
  navigator.clipboard.writeText(text);
  showToast(message, text);
}
function showToast(message, button_id) {
  let button = document.getElementById(button_id);
  let toast = document.getElementById("toast");
  button.setAttribute("disabled", "");
  toast.innerHTML = message;
  toast.classList.add("animate-fade-in");
  setTimeout(() => {
    toast.classList.add("animate-fade-out");
    setTimeout(() => {
      toast.classList.remove("animate-fade-in");
      toast.classList.remove("animate-fade-out");
      toast.innerHTML = "";
      button.removeAttribute("disabled");
    }, 500);
  }, 2000);
}
