export default Modal = {
  mounted() {
    this.el.addEventListener("showModal", (_e) => {
      this.el.showModal();
    });

    this.el.addEventListener("hideModal", (_e) => {
      this.el.close();
    });

    this.handleEvent("hideModal", ({ id: id }) => {
      if (id == this.el.id) {
        this.el.close();
      }
    });
  },
};
