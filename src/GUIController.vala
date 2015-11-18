class GUIController: Object {


    public GUIController(AppMain app, Controller controller) {

        this.movie_list = new Gee.ArrayList<MovieListItem>(null);
        this.appmain = app;

        // create window and initial contents
        this.init_base_ui();

        this.view_manager = new ViewManager(this.movie_list, this.view_container);
        //this.view_manager.play_movie.connect(this.play);
        //this.view_manager.show_detail_view.connect(this.show_detail_view);

        //attach main window to application
        //this.main_window.set_application(app);

        this.search_filter = this.genre_filter = "";

        this.show_window();

        print("show_all called\n");

    }

    // reference to the main Gtk.Application object
    private AppMain appmain;

    // reference to Controller object that created this object (used for connecing to signals)
    private Controller controller;

    // Controls the different views
    private ViewManager view_manager;


    // ############## GUI Items ########################################################

    public Gtk.Window main_window;

    private Gtk.Toolbar toolbar;

		private Gtk.ProgressBar progbar;

		private Granite.Widgets.SearchBar search_bar;

    private Granite.Widgets.AboutDialog about_dialog;

    private Granite.Widgets.ToolButtonWithMenu app_menu;

    private Granite.Widgets.ThinPaned pane;

    //private Gtk.Box view_container;

    private Granite.Widgets.SourceList source_list;

    private Granite.Widgets.SourceList.ExpandableItem source_category_genres;

    private Gtk.ScrolledWindow scrolled;

    private Gtk.Box view_container;

    private DetailView detail_view;

    // ##################################################################################


    // list to hold all items currently shown
    private Gee.ArrayList<MovieListItem> movie_list;

    private string[] genres;

    // Genre currently selected in the sidebar. Empty string means no genre selected.
    private string genre_filter;

    // Text in search bar. Empty string means no text.
    private string search_filter;

    // step size of progress bar
    private double progbar_step_size;

    public void show_window() {
    	this.main_window.show_all();
    	return;
    }

    private void quit() {

    	this.appmain.async_queue.push(new AsyncMessage("exit", null, null));
        Gtk.main_quit();

    }

    public void init_base_ui() {

        main_window = new Gtk.Window();
        main_window.set_default_size(1200, 600);
        main_window.set_title("Reels");
        main_window.set_icon_name("totem");

        main_window.destroy.connect(this.quit);

        // init main toolbar
        toolbar = new Gtk.Toolbar();

        // load movies button
        var button = new Gtk.ToolButton(null, null);
        button.set_icon_name("list-add-symbolic");
        button.clicked.connect(this.file_chooser);
        toolbar.insert(button, 0);

        // progress bar
        progbar = new Gtk.ProgressBar();
        var progbar_container_y = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        var progbar_container_x = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var progbar_toolitem = new Gtk.ToolItem();
        progbar_container_x.pack_start(progbar_container_y, true, false, 0);
        progbar_container_y.pack_start(progbar, true, false, 0);
        progbar.set_size_request(400, 2);
        progbar_toolitem.add(progbar_container_x);
        progbar_toolitem.set_expand(true);
        toolbar.insert(progbar_toolitem, 1);
        progbar.visible = false;

        // Searchbar
        this.search_bar = new Granite.Widgets.SearchBar("search movies");
        var search_bar_toolitem = new Gtk.ToolItem();
        search_bar_toolitem.add(search_bar);
        toolbar.insert(search_bar_toolitem, -2);
        this.search_bar.text_changed_pause.connect(this.on_search_update);



        var menu = new Gtk.Menu();
        var about_item = new Gtk.MenuItem.with_label("About");
        about_item.activate.connect(() => {
        	// About dialog
		    this.about_dialog = new Granite.Widgets.AboutDialog();
		    this.about_dialog.program_name = this.appmain.program_name;
		    this.about_dialog.authors = this.appmain.authors;
		    this.about_dialog.comments = this.appmain.comments;
		    this.about_dialog.bug = this.appmain.bug_link;
		    this.about_dialog.response.connect((widget, response_id) => {
		    	if (response_id == Gtk.ResponseType.CANCEL) this.about_dialog.destroy();;
		    });
		    this.about_dialog.show_all();
        });
        menu.append(about_item);
        var app_menu_image = new Gtk.Image.from_icon_name("document-properties-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        app_menu = new Granite.Widgets.ToolButtonWithMenu(app_menu_image, "", menu);
        toolbar.insert(app_menu, -1);

        var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        vbox.pack_start(toolbar, false, false, 0);

        //var frame = new Gtk.Frame(null);
        this.scrolled = new Gtk.ScrolledWindow(null, null);
        this.scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        this.scrolled.name = "content_area";
        this.view_container = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

        //frame.add(scrolled);
        //this.movie_item_container.set_homogeneous(false);
        //this.scrolled.add_with_viewport(movie_item_container);

        // SourceList
        this.source_list = new Granite.Widgets.SourceList();
        var source_all = new Granite.Widgets.SourceList.Item("All");
        var source_watched = new Granite.Widgets.SourceList.Item("Watched");
        var source_unwatched = new Granite.Widgets.SourceList.Item("Unwatched");
        this.source_category_genres = new Granite.Widgets.SourceList.ExpandableItem("Genres");
        var source_genres_all = new Granite.Widgets.SourceList.Item("All");
        source_category_genres.add(source_genres_all);
        var source_list_root = this.source_list.root;
        source_list_root.add(source_all);
        source_list_root.add(source_watched);
        source_list_root.add(source_unwatched);
        source_list_root.add(source_category_genres);
        this.source_list.item_selected.connect(this.on_source_list_item_selected);

			  this.pane = new Granite.Widgets.ThinPaned();
				pane.pack1(this.source_list, true, false);
				pane.pack2(this.view_container, true, false);
        pane.set_position(130);
        pane.name = "pane";
        pane.set_size_request(1000, -1);

        vbox.pack_start(pane, true, true, 0);

        main_window.add(vbox);

        // Gtk theming
        this.source_list.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
        toolbar.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
        var css_provider = new Gtk.CssProvider();
        //this.movie_item_container.name = "movie_item_container";
        css_provider.load_from_data("""
        	.list-view > GtkViewport,
        	#detail_view_container,
        	#static > *,
        	#review_scrolled {
        		background-color: #ffffff;
        	}

        	#static GtkButton {
        		background: #ffffff;
        	}

        	#static GtkButton:active {
        		background: #e0e0e0;
        	}

        	.control_button {
        		border-radius: 5;
        		background: #ffffff;
        	}

        	.list-view GtkSeparator {
        		border-style: solid;
        	}

        """, -1);
        (new Gtk.StyleContext()).add_provider_for_screen(this.main_window.get_screen(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

    }

    private void file_chooser() {

    	// The FileChooserDialog:
		Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
				"Select the directory with your movies", this.main_window, Gtk.FileChooserAction.SELECT_FOLDER,
				Gtk.Stock.CANCEL,
				Gtk.ResponseType.CANCEL,
				Gtk.Stock.OPEN,
				Gtk.ResponseType.ACCEPT);

		// Multiple files can not be selected:
		chooser.select_multiple = false;

		// get response and send command to controller thread
		var response = chooser.run ();
		if (response == Gtk.ResponseType.ACCEPT) {
			var file = chooser.get_file();
			print(file.get_path());
			GLib.File* file_ptr = file;
			var message = new AsyncMessage("scandir", (void*)file_ptr, file);
			this.appmain.async_queue.push(message);
			chooser.destroy();
		} else if (response == Gtk.ResponseType.CANCEL) {
			chooser.destroy();
		}
    }

    // Ready the progress bar with number of movies
    public void prepare_to_add(int num_steps, bool disable_view) {
        Gdk.threads_enter();
        this.progbar_step_size = 1.0/(double)num_steps;
        this.progbar.visible = true;
        this.scrolled.sensitive = !disable_view;
        Gdk.threads_leave();
        return;
    }

    public void finalise_adding() {
        Gdk.threads_enter();
        this.progbar_step_size = 0.0;
        this.progbar.visible = false;
        this.scrolled.sensitive = true;
        this.progbar.set_fraction(0.0);
        this.view_manager.show_items();
        Gdk.threads_leave();
        return;
    }

    // OLD: This functionality is to be moved to MovieListViewItem
    /*
    public void add_movie_item_OLD(Movie movie) {

        print("----adding to GUI\n");

        Gdk.threads_enter();

        var movie_item = new MovieItem(movie, this.play, this.show_detail_view);
        this.movie_item_container.pack_start(movie_item, false, false, 0);
        this.movie_item_list.add(movie_item);
        //movie_item.show_all();
        this.progbar.set_fraction(this.progbar.get_fraction() + this.progbar_step_size);

        this.update_genres_list(movie);


        Gdk.threads_leave();

    }
    */

    public void add_movie_item(Movie movie) {

        Gdk.threads_enter();

        var movie_list_item = new MovieListItem(movie);
        this.view_manager.item_added(movie_list_item);

        this.apply_filters(movie_list_item);
        this.view_manager.item_visibility_changed(movie_list_item);

        this.movie_list.add(movie_list_item);

        this.update_genres_list(movie);

        Gdk.threads_leave();

    }

    private void update_genres_list(Movie movie) {

    	for (uint iii = 0; iii < (movie.movie_info.genres.length); iii++) {
        	print("--%s\n", movie.movie_info.genres[iii]);

        	// Check if genre aready exists in genres list.
        	for (uint jjj = 0; jjj < (this.genres.length); jjj++) {
			    	if (movie.movie_info.genres[iii] == this.genres[jjj])
			    		return;
		  		}

        	// Add genre to side bar
        	var source_genre = new Granite.Widgets.SourceList.Item(movie.movie_info.genres[iii]);
			this.source_category_genres.add(source_genre);

			// Add genre to genre list
			this.genres += movie.movie_info.genres[iii];

        }

			return;

    }

    // This function connects to the play signal of the ViewManager.
    // It hides the application window and starts the movie using an external media player.
    public void play(Movie movie) {

        print("\n MOVIE NAME: %s\n\n", movie.movie_info.title);

    	string[] child_args = {"totem", movie.video_file.get_path()};

    	this.main_window.hide();



    	print("HIDDEN\n");

    	GLib.Pid child_pid;

    	GLib.Process.spawn_async(null, child_args, null,
    	    GLib.SpawnFlags.SEARCH_PATH |
    	    GLib.SpawnFlags.STDOUT_TO_DEV_NULL |
    	    GLib.SpawnFlags.STDERR_TO_DEV_NULL |
    	    GLib.SpawnFlags.DO_NOT_REAP_CHILD,
    	    null, out child_pid);

    	GLib.ChildWatch.add(child_pid, (pid, status) => {

    		GLib.Process.close_pid(child_pid);

    		this.main_window.present();

    		print("PRESENTED\n");

    	});

    }

    // DEPRECATED: This functionality is to be moved to ViewManager
    /*
    public void show_detail_view(Movie movie) {

    	this.view_container.remove(this.scrolled);

    	this.detail_view = new DetailView(movie, this.play, this.show_detail_view, this.show_list_view);

    	this.view_container.pack_start(this.detail_view, true, true, 0);

    	this.view_container.show_all();

    }
    */

    // DEPRECATED: This functionality is to be moved to ViewManager
    /*
    public void show_list_view() {

    	this.view_container.remove(this.detail_view);

    	this.view_container.pack_start(this.scrolled, true, true, 0);

    }
    */


    private void on_search_update(string search_text) {

    	this.search_filter = search_text;
    	this.refresh();

    }


    private void on_source_list_item_selected(Granite.Widgets.SourceList.Item? item) {

    	this.genre_filter = item.name;
    	this.refresh();

    }


    // TODO: make more efficient. Check if movie is already being shown.
    private void refresh() {

    	print("refresh() called\n");

    	var iter = this.movie_list.list_iterator();
    	while (iter.next() == true) {
    		var item = iter.get();
    		this.apply_filters(item);
    		this.view_manager.item_visibility_changed(item);
    	}

    }

    // This function checks whether a movie passes all filters like search and genres
    // and sets the visibility accordingly.
    // Does NOT fire the relevant signals. That is the duty of the caller.
    private void apply_filters(MovieListItem movie_list_item) {

        bool genre = false;
        bool search = false;

        genre = this.apply_genre_filter(movie_list_item);

        search = this.apply_search_filter(movie_list_item);

    	if (genre && search) {
    		movie_list_item.visible = true;
    	} else {
    		movie_list_item.visible = false;
    	}

    }

    private bool apply_search_filter(MovieListItem movie_list_item) {

    	if (this.search_filter == "")
    		return true;

        var regex = new GLib.Regex("\\Q" + this.search_filter + "\\E", GLib.RegexCompileFlags.CASELESS, 0);
		GLib.MatchInfo match_info;
		if (regex.match(movie_list_item.movie.movie_info.title, 0, out match_info))
			return true;
		else
		    return false;

    }

    private bool apply_genre_filter(MovieListItem movie_list_item) {

    	if (this.genre_filter == "" || this.genre_filter == "All")
    		return true;

        if (this.genre_filter in movie_list_item.movie.movie_info.genres)
            return true;
        else
            return false;

    }

}
