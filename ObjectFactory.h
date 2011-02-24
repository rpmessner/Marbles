///////////////////////////////////////////////////////////////////////////////
//
// ObjectFactory
//
// The ObjectFactory class is a object factory implementation.  It allows users
// to register and unregister classes during run-time by specifying a
// user-defined unique identifier per class.  Instances of any registered class
// can then be instantiated simply by calling the create method and passing the
// proper unique identifier.
//
///////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2004 Robert Geiman.
//
// Permission to copy, modify, and use this code for personal and commercial
// software is granted provided this copyright notice appears in all copies.
// This software is provided "as is" without any expressed or implied warranty.
//
// Any comments or questions can be sent to: rgeiman@buckeye-express.com
//
///////////////////////////////////////////////////////////////////////////////

#ifndef OBJECT_FACTORY_H
#define OBJECT_FACTORY_H


#include <hash_map>
#include "MacroRepeat.h"


template <typename CtorSignature, typename UniqueIdType> class ObjectFactory;

#define OBJECT_FACTORY(num)                                                                                 \
   template<typename BaseClassType MACRO_LIST_APPEND(num, MACRO_TEMPLATE_PARAMETER), typename ClassType>    \
   BaseClassType CreateObject(MACRO_LIST(num, MACRO_FUNCTION_PARAMETER))                                    \
   {                                                                                                        \
      return new ClassType MACRO_BEGIN_PAREN(num, MACRO_EMPTY_MACRO) MACRO_LIST(num, MACRO_FUNCTION_ARGUMENT) MACRO_END_PAREN(num, MACRO_EMPTY_MACRO); \
   }                                                                                                        \
                                                                                                            \
   template<typename BaseClassType MACRO_LIST_APPEND(num, MACRO_TEMPLATE_PARAMETER), typename UniqueIdType> \
   class ObjectFactory<BaseClassType (MACRO_LIST(num, MACRO_TEMPLATE_ARGUMENT)), UniqueIdType>              \
   {                                                                                                        \
   private:                                                                                                 \
      typedef BaseClassType (*CreateObjectFunc)(MACRO_LIST(num, MACRO_FUNCTION_PARAMETER));                 \
                                                                                                            \
   public:                                                                                                  \
      typedef typename std::map<UniqueIdType, CreateObjectFunc>::const_iterator ConstIterator;              \
      typedef typename std::map<UniqueIdType, CreateObjectFunc>::iterator Iterator;                         \
                                                                                                            \
                                                                                                            \
      template<typename ClassType>                                                                          \
      bool Register(UniqueIdType unique_id)                                                                 \
      {                                                                                                     \
         if (m_object_creator.find(unique_id) != m_object_creator.end())                                    \
            return false;                                                                                   \
                                                                                                            \
         m_object_creator[unique_id] = &CreateObject<BaseClassType MACRO_LIST_APPEND(num, MACRO_TEMPLATE_ARGUMENT), ClassType>; \
                                                                                                            \
         return true;                                                                                       \
      }                                                                                                     \
                                                                                                            \
      bool Unregister(UniqueIdType unique_id)                                                               \
      {                                                                                                     \
         return (m_object_creator.erase(unique_id) == 1);                                                   \
      }                                                                                                     \
                                                                                                            \
      BaseClassType Create(UniqueIdType unique_id MACRO_LIST_APPEND(num, MACRO_FUNCTION_PARAMETER))         \
      {                                                                                                     \
         Iterator iter = m_object_creator.find(unique_id);                                                  \
                                                                                                            \
         if (iter == m_object_creator.end())                                                                \
            return NULL;                                                                                    \
                                                                                                            \
         return ((*iter).second)(MACRO_LIST(num, MACRO_FUNCTION_ARGUMENT));                                 \
      }                                                                                                     \
                                                                                                            \
      ConstIterator GetBegin() const                                                                        \
      {                                                                                                     \
         return m_object_creator.begin();                                                                   \
      }                                                                                                     \
                                                                                                            \
      Iterator GetBegin()                                                                                   \
      {                                                                                                     \
         return m_object_creator.begin();                                                                   \
      }                                                                                                     \
                                                                                                            \
      ConstIterator GetEnd() const                                                                          \
      {                                                                                                     \
         return m_object_creator.end();                                                                     \
      }                                                                                                     \
                                                                                                            \
      Iterator GetEnd()                                                                                     \
      {                                                                                                     \
         return m_object_creator.end();                                                                     \
      }                                                                                                     \
                                                                                                            \
   protected:                                                                                               \
      std::hash_map<UniqueIdType, CreateObjectFunc> m_object_creator;                                            \
   };

MACRO_REPEAT(16, OBJECT_FACTORY)
#undef OBJECT_FACTORY

#endif