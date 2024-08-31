version(gtk4) {
	pragma(lib, "gtkd-4");
} 

import gtk.ColumnView;
class MyTreeView : ColumnView {
import gtk.StringList, gtk.TreeListModel, gtk.ListItem, gtk.SignalListItemFactory, gtk.MultiSelection, gtk.ColumnViewColumn;
public:
	this() {
		import std.stdio;
		list = new StringList([]);
		list.append("item1");
		list.append("item2");
		model = new TreeListModel(list, false, false, &create_list, cast(void*)this, null);
		factory = new SignalListItemFactory();
		factory.addOnSetup(
			delegate void(ListItem item, SignalListItemFactory factory) {
				import gtk.TreeExpander, gtk.Box, gtk.CheckButton, gtk.Label;
				auto expander = new TreeExpander;
				auto box = new Box(GtkOrientation.HORIZONTAL, 8);
				auto check = new CheckButton;
				auto label = new Label("");
				box.append(check);
				box.append(label);
				expander.setChild(box);
				item.setChild(expander);
			});
		factory.addOnBind(
			delegate void(ListItem item, SignalListItemFactory factory) {
				import gtk.TreeExpander, gtk.Box, gtk.CheckButton, gtk.Label, gtk.TreeListRow, gtk.StringObject;
				auto expander = cast(TreeExpander)item.getChild();
				auto box      = cast(Box)         expander.getChild();
				auto check    = cast(CheckButton) box.getFirstChild();
				auto label    = cast(Label)       check.getNextSibling();
				auto row      = cast(TreeListRow) item.getItem();
				auto str      = cast(StringObject)row.getItem();
				label.setText(str.getString());
				expander.setListRow(row);
			});
		selection = new MultiSelection(model);
		super(selection);
		column = new ColumnViewColumn("111",factory);
		appendColumn(column);
	}

private:
	extern(C) 
	static GListModel* create_list(void* item, void* user_data) {
		auto self = cast(MyTreeView)user_data;
		import gtk.StringList, gtk.TreeListModel, gtk.StringObject;
		import std.typecons;
		string str = scoped!StringObject(cast(GtkStringObject*) item).getString;
		auto list = new StringList(cast(string[])null);
		       if (str == "item1")   { list.append("item1_a");
		                               list.append("item1_b");
		                               list.append("item1_c");
		} else if (str == "item2")   { list.append("item2_x");
		                               list.append("item2_y");
		                               list.append("item2_z");
		} else if (str == "item1_a") { list.append("item1_a_x");
		                               list.append("item1_a_y");
		                               list.append("item1_a_z");
		}
		return cast(GListModel*)list.getStringListStruct;
	}

private:
	StringList list;
	TreeListModel model;
	SignalListItemFactory factory;
	MultiSelection selection;
	ColumnViewColumn column;
}

import gtk.Application, gtk.ApplicationWindow;
class MainWindow : ApplicationWindow
{
	MyTreeView view;
	this(Application application) {
		super(application);
		setChild(view = new MyTreeView);
		setSizeRequest(200,300);
		present();
	}
}

int main(string[] args) {
	import gtk.Application;
	auto application = new gtk.Application.Application("my.application", GApplicationFlags.NON_UNIQUE);

	import gio.Application;
	application.addOnActivate(
		delegate void(gio.Application.Application app) {
			auto window = new MainWindow(application);
	});

	application.run(args);

	return 0;
}