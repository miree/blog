import gtk4;



extern(C) static void
signal_list_item_factory_setup(GtkSignalListItemFactory* self,
  GObject* object,
  gpointer user_data) 
{
  import std.stdio;
  //writeln("setup");
  auto expander = gtk_tree_expander_new();
  auto checkbutton = gtk_check_button_new();
  auto label = gtk_label_new(null);
  auto box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
  gtk_box_append(cast(GtkBox*)box, checkbutton);
  gtk_box_append(cast(GtkBox*)box, label);
  gtk_tree_expander_set_child(cast(GtkTreeExpander*)expander, box);
  gtk_tree_expander_set_hide_expander(cast(GtkTreeExpander*)expander, false);
  gtk_list_item_set_child((cast(GtkListItem*)object), expander);
}
extern(C) static void
signal_list_item_factory_bind(GtkSignalListItemFactory* self,
  GObject* object,
  gpointer user_data) 
{
  import std.conv;
  auto list_item = cast(GtkListItem*)object;
  auto expander = cast(GtkTreeExpander*)gtk_list_item_get_child(list_item);
  auto box = cast(GtkBox*)gtk_tree_expander_get_child(expander);
  auto checkbutton = cast(GtkCheckButton*)gtk_widget_get_first_child(cast(GtkWidget*)box);
  auto label = cast(GtkLabel*)gtk_widget_get_next_sibling(cast(GtkWidget*)checkbutton);
  // get the content (string) of the list model row
  auto tree_list_row = cast(GtkTreeListRow*)gtk_list_item_get_item(list_item);
  auto str_obj  = cast(GtkStringObject*)gtk_tree_list_row_get_item(tree_list_row);
  const char* str = gtk_string_object_get_string(cast(GtkStringObject*)str_obj);
  char[64] buf;
  import core.stdc.stdio;
  snprintf(buf.ptr,64,"%s -> %d", str, gtk_list_item_get_position(list_item));
  gtk_label_set_text(label, buf.ptr);
  gtk_tree_expander_set_list_row(cast(GtkTreeExpander*)expander, tree_list_row);
}

extern(C) static void
signal_list_item_factory_unbind(GtkSignalListItemFactory* self,
  GObject* object,
  gpointer user_data) 
{
  import std.stdio;
  import std.conv;
  auto item = cast(GtkListItem*)object;
  //writeln("unbind "~gtk_list_item_get_position(item).to!string);
}

extern(C) static void
signal_list_item_factory_teardown(GtkSignalListItemFactory* self,
  GObject* object,
  gpointer user_data) 
{
  import std.stdio;
  //writeln("teardown");
}

extern(C) 
static GListModel*
tree_list_model_create_model(
  GObject* item,
  gpointer user_data
)
{
  import std.stdio;
  //writeln("tree_list_model_create_model");
  return null;
}
extern(C)
GListModel* treelist_listmodel_create(void* item,
                                      void* user_data) 
{
  import std.stdio, std.conv;
  auto str_obj = cast(GtkStringObject*)(item);
  auto str = gtk_string_object_get_string(str_obj).to!string;
  import core.stdc.string;
  GtkStringList* string_list = gtk_string_list_new(null); // this implements GListModel

  if (str == "item1") {
    gtk_string_list_append(string_list, "item1_a");
    gtk_string_list_append(string_list, "item1_b");
    gtk_string_list_append(string_list, "item1_c");
  } else if (str == "item2") {
    gtk_string_list_append(string_list, "item2_x");
    gtk_string_list_append(string_list, "item2_y");
    gtk_string_list_append(string_list, "item2_z");
  } else if (str == "item1_a") {
    gtk_string_list_append(string_list, "item1_a_x");
    gtk_string_list_append(string_list, "item1_a_y");
    gtk_string_list_append(string_list, "item1_a_z");
  }
  return cast(GListModel*)string_list;
}

extern(C) 
static void
activate (GtkApplication *app,
          gpointer        user_data)
{
  GtkWidget *window;
  GtkWidget *frame;
  GtkWidget *box;
  GtkEventController *motion_controller;

  window = gtk_application_window_new (app);
  gtk_window_set_title (cast(GtkWindow*)window, "ListView");

  frame = gtk_frame_new (null);
  gtk_window_set_child (cast(GtkWindow*)window, frame);

  box = gtk_box_new(GTK_ORIENTATION_VERTICAL,0);
  gtk_frame_set_child (cast(GtkFrame*)frame, box);


  GtkStringList* string_list = gtk_string_list_new(null); // this implements GListModel
  gtk_string_list_append(string_list, "item1");
  gtk_string_list_append(string_list, "item2");
  gboolean passthrough;
  gboolean autoexpand;
  GtkTreeListModel* treelistmodel = cast(GtkTreeListModel*)gtk_tree_list_model_new(cast(GListModel*)string_list,
    passthrough=false, 
    autoexpand=false,
    &treelist_listmodel_create,null,null);
  GtkSelectionModel* selection_model = cast(GtkSelectionModel*)gtk_multi_selection_new(cast(GListModel*)treelistmodel);
  GtkListItemFactory *signal_list_item_factory = gtk_signal_list_item_factory_new();
  g_signal_connect(signal_list_item_factory, "setup", &signal_list_item_factory_setup, null);
  g_signal_connect(signal_list_item_factory, "bind", &signal_list_item_factory_bind, null);
  g_signal_connect(signal_list_item_factory, "unbind", &signal_list_item_factory_unbind, null);
  g_signal_connect(signal_list_item_factory, "teardown", &signal_list_item_factory_teardown, null);
  GtkColumnViewColumn* col1 = cast(GtkColumnViewColumn*)gtk_column_view_column_new("1111", signal_list_item_factory);
  GtkColumnView* col_view = cast(GtkColumnView*)gtk_column_view_new(selection_model);
  gtk_column_view_append_column(col_view, col1);
  GtkScrolledWindow *scrolled_window = cast(GtkScrolledWindow*)gtk_scrolled_window_new();
  gtk_scrolled_window_set_child(scrolled_window, cast(GtkWidget*)col_view);
  gtk_widget_set_size_request (cast(GtkWidget*)scrolled_window, 200, 300);
  gtk_box_append(cast(GtkBox*)box, cast(GtkWidget*)scrolled_window);

  gtk_window_present (cast(GtkWindow*)window);
}

int
main (string[] args)
{

	GtkApplication *app;
	int status; 

	app = gtk_application_new ("org.gtk.example", G_APPLICATION_DEFAULT_FLAGS);
	scope(exit) g_object_unref (app);
	

	g_signal_connect!(GtkApplication*)(app, "activate".toStringz, &activate, cast(gpointer)null);

	int argc = cast(int)args.length;
	char* argv = cast(char*)args[0].ptr;
	return g_application_run (cast(GApplication*)app, argc, &argv);
}
