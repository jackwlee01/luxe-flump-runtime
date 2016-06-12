#ifndef INCLUDED_Movie
#define INCLUDED_Movie

#ifndef HXCPP_H
#include <hxcpp.h>
#endif

#ifndef INCLUDED_luxe_Entity
#include <luxe/Entity.h>
#endif
HX_DECLARE_CLASS0(Movie)
HX_DECLARE_CLASS1(luxe,Emitter)
HX_DECLARE_CLASS1(luxe,Entity)
HX_DECLARE_CLASS1(luxe,Objects)


class HXCPP_CLASS_ATTRIBUTES  Movie_obj : public ::luxe::Entity_obj{
	public:
		typedef ::luxe::Entity_obj super;
		typedef Movie_obj OBJ_;
		Movie_obj();
		Void __construct(::String id);

	public:
		inline void *operator new( size_t inSize, bool inContainer=true,const char *inName="Movie")
			{ return hx::Object::operator new(inSize,inContainer,inName); }
		static hx::ObjectPtr< Movie_obj > __new(::String id);
		static Dynamic __CreateEmpty();
		static Dynamic __Create(hx::DynamicArray inArgs);
		//~Movie_obj();

		HX_DO_RTTI_ALL;
		Dynamic __Field(const ::String &inString, hx::PropertyAccess inCallProp);
		static void __register();
		::String __ToString() const { return HX_HCSTRING("Movie","\x90","\x3f","\x93","\x9f"); }

		virtual Void init( );

		virtual Void ondestroy( );

};


#endif /* INCLUDED_Movie */
