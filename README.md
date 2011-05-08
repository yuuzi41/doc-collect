# DocCollect - DAV-ed Document Management System

The DocCollect is a rails application, for document(scanned ebooks,pdfs,etc)  management.

Documents managed this-app is attached Attributes(author, publisher, categories, etc).

This Application provides Web DAV interface. You can access the documents by WebDAV, mountable by win,mac,linux and etc systems. And You can narrowing-down your find documents by Attributes.

This app require Ruby 1.9.2 and Ruby On Rails 3.0.7.

I'm sorry this app is supporting japanese only now.

## Install

you should do above.

* database settings (example: config/database.yml.sqlite3)
* database migration
* deploy your documents to the place your app server can access
* deploy app (phusion passenger is recommend)
* setup categories/attributes/documents
