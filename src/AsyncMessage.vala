class AsyncMessage {

	public string command;

	public void* data;

	public GLib.File? file;

	public AsyncMessage(string com, void* dat, GLib.File _file) {
		this.command = com;
		this.data = dat;
		this.file = _file;
	}

}
