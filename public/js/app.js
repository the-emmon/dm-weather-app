function checkZip() {
  var reg = /^[0-9]{5}$/;
  var field = document.zip.zipcode.value;
  if (!field.match(reg)) {
      alert("Not a properly formatted zipcode!");
      return false;
  };
};
