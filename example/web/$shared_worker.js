(function dartProgram(){function copyProperties(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
b[q]=a[q]}}function mixinPropertiesHard(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
if(!b.hasOwnProperty(q)){b[q]=a[q]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var s=function(){}
s.prototype={p:{}}
var r=new s()
if(!(Object.getPrototypeOf(r)&&Object.getPrototypeOf(r).p===s.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var q=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(q))return true}}catch(p){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var s=Object.create(b.prototype)
copyProperties(a.prototype,s)
a.prototype=s}}function inheritMany(a,b){for(var s=0;s<b.length;s++){inherit(b[s],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){var r=d()
if(a[b]!==s){A.it(b)}a[b]=r}var q=a[b]
a[c]=function(){return q}
return q}}function makeConstList(a){a.immutable$list=Array
a.fixed$length=Array
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var s=0;s<a.length;++s){convertToFastObject(a[s])}}var y=0
function instanceTearOffGetter(a,b){var s=null
return a?function(c){if(s===null)s=A.dR(b)
return new s(c,this)}:function(){if(s===null)s=A.dR(b)
return new s(this,null)}}function staticTearOffGetter(a){var s=null
return function(){if(s===null)s=A.dR(a).prototype
return s}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var s=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var r=staticTearOffGetter(s)
a[b]=r}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var s=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var r=instanceTearOffGetter(c,s)
a[b]=r}function setOrUpdateInterceptorsByTag(a){var s=v.interceptorsByTag
if(!s){v.interceptorsByTag=a
return}copyProperties(a,s)}function setOrUpdateLeafTags(a){var s=v.leafTags
if(!s){v.leafTags=a
return}copyProperties(a,s)}function updateTypes(a){var s=v.types
var r=s.length
s.push.apply(s,a)
return r}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var s=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},r=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:s(0,0,null,["$0"],0),_instance_1u:s(0,1,null,["$1"],0),_instance_2u:s(0,2,null,["$2"],0),_instance_0i:s(1,0,null,["$0"],0),_instance_1i:s(1,1,null,["$1"],0),_instance_2i:s(1,2,null,["$2"],0),_static_0:r(0,null,["$0"],0),_static_1:r(1,null,["$1"],0),_static_2:r(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
e_(a,b,c,d){return{i:a,p:b,e:c,x:d}},
dU(a){var s,r,q,p,o,n=a[v.dispatchPropertyName]
if(n==null)if($.dV==null){A.id()
n=a[v.dispatchPropertyName]}if(n!=null){s=n.p
if(!1===s)return n.i
if(!0===s)return a
r=Object.getPrototypeOf(a)
if(s===r)return n.i
if(n.e===r)throw A.b(A.aO("Return interceptor for "+A.p(s(a,n))))}q=a.constructor
if(q==null)p=null
else{o=$.d_
if(o==null)o=$.d_=v.getIsolateTag("_$dart_js")
p=q[o]}if(p!=null)return p
p=A.ij(a)
if(p!=null)return p
if(typeof a=="function")return B.y
s=Object.getPrototypeOf(a)
if(s==null)return B.j
if(s===Object.prototype)return B.j
if(typeof q=="function"){o=$.d_
if(o==null)o=$.d_=v.getIsolateTag("_$dart_js")
Object.defineProperty(q,o,{value:B.d,enumerable:false,writable:true,configurable:true})
return B.d}return B.d},
fz(a,b){if(a<0||a>4294967295)throw A.b(A.ei(a,0,4294967295,"length",null))
return J.fB(new Array(a),b)},
fA(a,b){if(a<0)throw A.b(A.N("Length must be a non-negative integer: "+a,null))
return A.an(new Array(a),b.h("r<0>"))},
fB(a,b){return J.ee(A.an(a,b.h("r<0>")))},
ee(a){a.fixed$length=Array
return a},
a2(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.aA.prototype
return J.br.prototype}if(typeof a=="string")return J.a8.prototype
if(a==null)return J.aB.prototype
if(typeof a=="boolean")return J.bq.prototype
if(Array.isArray(a))return J.r.prototype
if(typeof a!="object"){if(typeof a=="function")return J.P.prototype
if(typeof a=="symbol")return J.aE.prototype
if(typeof a=="bigint")return J.aC.prototype
return a}if(a instanceof A.c)return a
return J.dU(a)},
f0(a){if(typeof a=="string")return J.a8.prototype
if(a==null)return a
if(Array.isArray(a))return J.r.prototype
if(typeof a!="object"){if(typeof a=="function")return J.P.prototype
if(typeof a=="symbol")return J.aE.prototype
if(typeof a=="bigint")return J.aC.prototype
return a}if(a instanceof A.c)return a
return J.dU(a)},
a3(a){if(a==null)return a
if(Array.isArray(a))return J.r.prototype
if(typeof a!="object"){if(typeof a=="function")return J.P.prototype
if(typeof a=="symbol")return J.aE.prototype
if(typeof a=="bigint")return J.aC.prototype
return a}if(a instanceof A.c)return a
return J.dU(a)},
ba(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.a2(a).B(a,b)},
fh(a,b){return J.a3(a).R(a,b)},
fi(a){return J.a3(a).gaF(a)},
dx(a){return J.a2(a).gm(a)},
fj(a){return J.a3(a).gq(a)},
e2(a){return J.a3(a).gaK(a)},
e3(a){return J.f0(a).gk(a)},
e4(a){return J.a2(a).gl(a)},
dy(a,b,c){return J.a3(a).T(a,b,c)},
a6(a){return J.a2(a).i(a)},
bm:function bm(){},
bq:function bq(){},
aB:function aB(){},
aD:function aD(){},
Q:function Q(){},
bJ:function bJ(){},
aP:function aP(){},
P:function P(){},
aC:function aC(){},
aE:function aE(){},
r:function r(a){this.$ti=a},
cp:function cp(a){this.$ti=a},
bb:function bb(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
bs:function bs(){},
aA:function aA(){},
br:function br(){},
a8:function a8(){}},A={dD:function dD(){},
eo(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
fR(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
aq(a,b,c){return a},
dX(a){var s,r
for(s=$.a5.length,r=0;r<s;++r)if(a===$.a5[r])return!0
return!1},
fE(a,b,c,d){if(t.V.b(a))return new A.av(a,b,c.h("@<0>").t(d).h("av<1,2>"))
return new A.Y(a,b,c.h("@<0>").t(d).h("Y<1,2>"))},
co(){return new A.Z("No element")},
as:function as(a,b){this.a=a
this.$ti=b},
at:function at(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
bu:function bu(a){this.a=a},
cu:function cu(){},
e:function e(){},
G:function G(){},
a9:function a9(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
Y:function Y(a,b,c){this.a=a
this.b=b
this.$ti=c},
av:function av(a,b,c){this.a=a
this.b=b
this.$ti=c},
bx:function bx(a,b,c){var _=this
_.a=null
_.b=a
_.c=b
_.$ti=c},
H:function H(a,b,c){this.a=a
this.b=b
this.$ti=c},
ax:function ax(){},
f5(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
j0(a,b){var s
if(b!=null){s=b.x
if(s!=null)return s}return t.p.b(a)},
p(a){var s
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
s=J.a6(a)
return s},
aL(a){var s,r=$.eh
if(r==null)r=$.eh=Symbol("identityHashCode")
s=a[r]
if(s==null){s=Math.random()*0x3fffffff|0
a[r]=s}return s},
bK(a){return A.fG(a)},
fG(a){var s,r,q,p
if(a instanceof A.c)return A.u(A.ar(a),null)
s=J.a2(a)
if(s===B.u||s===B.z||t.o.b(a)){r=B.f(a)
if(r!=="Object"&&r!=="")return r
q=a.constructor
if(typeof q=="function"){p=q.name
if(typeof p=="string"&&p!=="Object"&&p!=="")return p}}return A.u(A.ar(a),null)},
fP(a){if(typeof a=="number"||A.db(a))return J.a6(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.O)return a.i(0)
return"Instance of '"+A.bK(a)+"'"},
ad(a){if(a.date===void 0)a.date=new Date(a.a)
return a.date},
fO(a){var s=A.ad(a).getUTCFullYear()+0
return s},
fM(a){var s=A.ad(a).getUTCMonth()+1
return s},
fI(a){var s=A.ad(a).getUTCDate()+0
return s},
fJ(a){var s=A.ad(a).getUTCHours()+0
return s},
fL(a){var s=A.ad(a).getUTCMinutes()+0
return s},
fN(a){var s=A.ad(a).getUTCSeconds()+0
return s},
fK(a){var s=A.ad(a).getUTCMilliseconds()+0
return s},
fH(a){var s=a.$thrownJsError
if(s==null)return null
return A.y(s)},
eZ(a,b){var s,r="index"
if(!A.eL(b))return new A.E(!0,b,r,null)
s=J.e3(a)
if(b<0||b>=s)return A.fu(b,s,a,r)
return new A.aM(null,null,!0,b,r,"Value not in range")},
b(a){return A.f2(new Error(),a)},
f2(a,b){var s
if(b==null)b=new A.I()
a.dartException=b
s=A.iu
if("defineProperty" in Object){Object.defineProperty(a,"message",{get:s})
a.name=""}else a.toString=s
return a},
iu(){return J.a6(this.dartException)},
a4(a){throw A.b(a)},
is(a,b){throw A.f2(b,a)},
ir(a){throw A.b(A.au(a))},
J(a){var s,r,q,p,o,n
a=A.iq(a.replace(String({}),"$receiver$"))
s=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(s==null)s=A.an([],t.s)
r=s.indexOf("\\$arguments\\$")
q=s.indexOf("\\$argumentsExpr\\$")
p=s.indexOf("\\$expr\\$")
o=s.indexOf("\\$method\\$")
n=s.indexOf("\\$receiver\\$")
return new A.cx(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),r,q,p,o,n)},
cy(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(s){return s.message}}(a)},
ep(a){return function($expr$){try{$expr$.$method$}catch(s){return s.message}}(a)},
dE(a,b){var s=b==null,r=s?null:b.method
return new A.bt(a,r,s?null:b.receiver)},
D(a){if(a==null)return new A.ct(a)
if(a instanceof A.aw)return A.U(a,a.a)
if(typeof a!=="object")return a
if("dartException" in a)return A.U(a,a.dartException)
return A.hR(a)},
U(a,b){if(t.Q.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
hR(a){var s,r,q,p,o,n,m,l,k,j,i,h,g
if(!("message" in a))return a
s=a.message
if("number" in a&&typeof a.number=="number"){r=a.number
q=r&65535
if((B.b.bc(r,16)&8191)===10)switch(q){case 438:return A.U(a,A.dE(A.p(s)+" (Error "+q+")",null))
case 445:case 5007:A.p(s)
return A.U(a,new A.aK())}}if(a instanceof TypeError){p=$.f6()
o=$.f7()
n=$.f8()
m=$.f9()
l=$.fc()
k=$.fd()
j=$.fb()
$.fa()
i=$.ff()
h=$.fe()
g=p.u(s)
if(g!=null)return A.U(a,A.dE(s,g))
else{g=o.u(s)
if(g!=null){g.method="call"
return A.U(a,A.dE(s,g))}else if(n.u(s)!=null||m.u(s)!=null||l.u(s)!=null||k.u(s)!=null||j.u(s)!=null||m.u(s)!=null||i.u(s)!=null||h.u(s)!=null)return A.U(a,new A.aK())}return A.U(a,new A.bQ(typeof s=="string"?s:""))}if(a instanceof RangeError){if(typeof s=="string"&&s.indexOf("call stack")!==-1)return new A.aN()
s=function(b){try{return String(b)}catch(f){}return null}(a)
return A.U(a,new A.E(!1,null,null,typeof s=="string"?s.replace(/^RangeError:\s*/,""):s))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof s=="string"&&s==="too much recursion")return new A.aN()
return a},
y(a){var s
if(a instanceof A.aw)return a.b
if(a==null)return new A.b0(a)
s=a.$cachedTrace
if(s!=null)return s
s=new A.b0(a)
if(typeof a==="object")a.$cachedTrace=s
return s},
ds(a){if(a==null)return J.dx(a)
if(typeof a=="object")return A.aL(a)
return J.dx(a)},
i4(a,b){var s,r,q,p=a.length
for(s=0;s<p;s=q){r=s+1
q=r+1
b.v(0,a[s],a[r])}return b},
hu(a,b,c,d,e,f){switch(b){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw A.b(new A.cM("Unsupported number of arguments for wrapped closure"))},
b7(a,b){var s=a.$identity
if(!!s)return s
s=A.hZ(a,b)
a.$identity=s
return s},
hZ(a,b){var s
switch(b){case 0:s=a.$0
break
case 1:s=a.$1
break
case 2:s=a.$2
break
case 3:s=a.$3
break
case 4:s=a.$4
break
default:s=null}if(s!=null)return s.bind(a)
return function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,A.hu)},
fq(a2){var s,r,q,p,o,n,m,l,k,j,i=a2.co,h=a2.iS,g=a2.iI,f=a2.nDA,e=a2.aI,d=a2.fs,c=a2.cs,b=d[0],a=c[0],a0=i[b],a1=a2.fT
a1.toString
s=h?Object.create(new A.bM().constructor.prototype):Object.create(new A.a7(null,null).constructor.prototype)
s.$initialize=s.constructor
r=h?function static_tear_off(){this.$initialize()}:function tear_off(a3,a4){this.$initialize(a3,a4)}
s.constructor=r
r.prototype=s
s.$_name=b
s.$_target=a0
q=!h
if(q)p=A.e9(b,a0,g,f)
else{s.$static_name=b
p=a0}s.$S=A.fm(a1,h,g)
s[a]=p
for(o=p,n=1;n<d.length;++n){m=d[n]
if(typeof m=="string"){l=i[m]
k=m
m=l}else k=""
j=c[n]
if(j!=null){if(q)m=A.e9(k,m,g,f)
s[j]=m}if(n===e)o=m}s.$C=o
s.$R=a2.rC
s.$D=a2.dV
return r},
fm(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.b("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.fk)}throw A.b("Error in functionType of tearoff")},
fn(a,b,c,d){var s=A.e8
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,s)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,s)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,s)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,s)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,s)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,s)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,s)}},
e9(a,b,c,d){if(c)return A.fp(a,b,d)
return A.fn(b.length,d,a,b)},
fo(a,b,c,d){var s=A.e8,r=A.fl
switch(b?-1:a){case 0:throw A.b(new A.bL("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,r,s)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,r,s)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,r,s)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,r,s)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,r,s)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,r,s)
default:return function(e,f,g){return function(){var q=[g(this)]
Array.prototype.push.apply(q,arguments)
return e.apply(f(this),q)}}(d,r,s)}},
fp(a,b,c){var s,r
if($.e6==null)$.e6=A.e5("interceptor")
if($.e7==null)$.e7=A.e5("receiver")
s=b.length
r=A.fo(s,c,a,b)
return r},
dR(a){return A.fq(a)},
fk(a,b){return A.d6(v.typeUniverse,A.ar(a.a),b)},
e8(a){return a.a},
fl(a){return a.b},
e5(a){var s,r,q,p=new A.a7("receiver","interceptor"),o=J.ee(Object.getOwnPropertyNames(p))
for(s=o.length,r=0;r<s;++r){q=o[r]
if(p[q]===a)return q}throw A.b(A.N("Field name "+a+" not found.",null))},
j1(a){throw A.b(new A.bW(a))},
i9(a){return v.getIsolateTag(a)},
ij(a){var s,r,q,p,o,n=$.f1.$1(a),m=$.dg[n]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.dl[n]
if(s!=null)return s
r=v.interceptorsByTag[n]
if(r==null){q=$.eV.$2(a,n)
if(q!=null){m=$.dg[q]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.dl[q]
if(s!=null)return s
r=v.interceptorsByTag[q]
n=q}}if(r==null)return null
s=r.prototype
p=n[0]
if(p==="!"){m=A.dr(s)
$.dg[n]=m
Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}if(p==="~"){$.dl[n]=s
return s}if(p==="-"){o=A.dr(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}if(p==="+")return A.f3(a,s)
if(p==="*")throw A.b(A.aO(n))
if(v.leafTags[n]===true){o=A.dr(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}else return A.f3(a,s)},
f3(a,b){var s=Object.getPrototypeOf(a)
Object.defineProperty(s,v.dispatchPropertyName,{value:J.e_(b,s,null,null),enumerable:false,writable:true,configurable:true})
return b},
dr(a){return J.e_(a,!1,null,!!a.$iv)},
il(a,b,c){var s=b.prototype
if(v.leafTags[a]===true)return A.dr(s)
else return J.e_(s,c,null,null)},
id(){if(!0===$.dV)return
$.dV=!0
A.ie()},
ie(){var s,r,q,p,o,n,m,l
$.dg=Object.create(null)
$.dl=Object.create(null)
A.ic()
s=v.interceptorsByTag
r=Object.getOwnPropertyNames(s)
if(typeof window!="undefined"){window
q=function(){}
for(p=0;p<r.length;++p){o=r[p]
n=$.f4.$1(o)
if(n!=null){m=A.il(o,s[o],n)
if(m!=null){Object.defineProperty(n,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
q.prototype=n}}}}for(p=0;p<r.length;++p){o=r[p]
if(/^[A-Za-z_]/.test(o)){l=s[o]
s["!"+o]=l
s["~"+o]=l
s["-"+o]=l
s["+"+o]=l
s["*"+o]=l}}},
ic(){var s,r,q,p,o,n,m=B.l()
m=A.ap(B.m,A.ap(B.n,A.ap(B.h,A.ap(B.h,A.ap(B.o,A.ap(B.p,A.ap(B.q(B.f),m)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){s=dartNativeDispatchHooksTransformer
if(typeof s=="function")s=[s]
if(Array.isArray(s))for(r=0;r<s.length;++r){q=s[r]
if(typeof q=="function")m=q(m)||m}}p=m.getTag
o=m.getUnknownTag
n=m.prototypeForTag
$.f1=new A.di(p)
$.eV=new A.dj(o)
$.f4=new A.dk(n)},
ap(a,b){return a(b)||b},
i0(a,b){var s=b.length,r=v.rttc[""+s+";"+a]
if(r==null)return null
if(s===0)return r
if(s===r.length)return r.apply(null,b)
return r(b)},
iq(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
cx:function cx(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
aK:function aK(){},
bt:function bt(a,b,c){this.a=a
this.b=b
this.c=c},
bQ:function bQ(a){this.a=a},
ct:function ct(a){this.a=a},
aw:function aw(a,b){this.a=a
this.b=b},
b0:function b0(a){this.a=a
this.b=null},
O:function O(){},
bf:function bf(){},
bg:function bg(){},
bO:function bO(){},
bM:function bM(){},
a7:function a7(a,b){this.a=a
this.b=b},
bW:function bW(a){this.a=a},
bL:function bL(a){this.a=a},
W:function W(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
cq:function cq(a,b){this.a=a
this.b=b
this.c=null},
aF:function aF(a,b){this.a=a
this.$ti=b},
bv:function bv(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
di:function di(a){this.a=a},
dj:function dj(a){this.a=a},
dk:function dk(a){this.a=a},
a0(a,b,c){if(a>>>0!==a||a>=c)throw A.b(A.eZ(b,a))},
by:function by(){},
aI:function aI(){},
bz:function bz(){},
ac:function ac(){},
aG:function aG(){},
aH:function aH(){},
bA:function bA(){},
bB:function bB(){},
bC:function bC(){},
bD:function bD(){},
bE:function bE(){},
bF:function bF(){},
bG:function bG(){},
aJ:function aJ(){},
bH:function bH(){},
aX:function aX(){},
aY:function aY(){},
aZ:function aZ(){},
b_:function b_(){},
ej(a,b){var s=b.c
return s==null?b.c=A.dO(a,b.x,!0):s},
dG(a,b){var s=b.c
return s==null?b.c=A.b3(a,"F",[b.x]):s},
ek(a){var s=a.w
if(s===6||s===7||s===8)return A.ek(a.x)
return s===12||s===13},
fQ(a){return a.as},
f_(a){return A.c5(v.typeUniverse,a,!1)},
S(a1,a2,a3,a4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=a2.w
switch(a0){case 5:case 1:case 2:case 3:case 4:return a2
case 6:s=a2.x
r=A.S(a1,s,a3,a4)
if(r===s)return a2
return A.eD(a1,r,!0)
case 7:s=a2.x
r=A.S(a1,s,a3,a4)
if(r===s)return a2
return A.dO(a1,r,!0)
case 8:s=a2.x
r=A.S(a1,s,a3,a4)
if(r===s)return a2
return A.eB(a1,r,!0)
case 9:q=a2.y
p=A.ao(a1,q,a3,a4)
if(p===q)return a2
return A.b3(a1,a2.x,p)
case 10:o=a2.x
n=A.S(a1,o,a3,a4)
m=a2.y
l=A.ao(a1,m,a3,a4)
if(n===o&&l===m)return a2
return A.dM(a1,n,l)
case 11:k=a2.x
j=a2.y
i=A.ao(a1,j,a3,a4)
if(i===j)return a2
return A.eC(a1,k,i)
case 12:h=a2.x
g=A.S(a1,h,a3,a4)
f=a2.y
e=A.hO(a1,f,a3,a4)
if(g===h&&e===f)return a2
return A.eA(a1,g,e)
case 13:d=a2.y
a4+=d.length
c=A.ao(a1,d,a3,a4)
o=a2.x
n=A.S(a1,o,a3,a4)
if(c===d&&n===o)return a2
return A.dN(a1,n,c,!0)
case 14:b=a2.x
if(b<a4)return a2
a=a3[b-a4]
if(a==null)return a2
return a
default:throw A.b(A.bd("Attempted to substitute unexpected RTI kind "+a0))}},
ao(a,b,c,d){var s,r,q,p,o=b.length,n=A.d7(o)
for(s=!1,r=0;r<o;++r){q=b[r]
p=A.S(a,q,c,d)
if(p!==q)s=!0
n[r]=p}return s?n:b},
hP(a,b,c,d){var s,r,q,p,o,n,m=b.length,l=A.d7(m)
for(s=!1,r=0;r<m;r+=3){q=b[r]
p=b[r+1]
o=b[r+2]
n=A.S(a,o,c,d)
if(n!==o)s=!0
l.splice(r,3,q,p,n)}return s?l:b},
hO(a,b,c,d){var s,r=b.a,q=A.ao(a,r,c,d),p=b.b,o=A.ao(a,p,c,d),n=b.c,m=A.hP(a,n,c,d)
if(q===r&&o===p&&m===n)return b
s=new A.c_()
s.a=q
s.b=o
s.c=m
return s},
an(a,b){a[v.arrayRti]=b
return a},
eX(a){var s=a.$S
if(s!=null){if(typeof s=="number")return A.ib(s)
return a.$S()}return null},
ig(a,b){var s
if(A.ek(b))if(a instanceof A.O){s=A.eX(a)
if(s!=null)return s}return A.ar(a)},
ar(a){if(a instanceof A.c)return A.x(a)
if(Array.isArray(a))return A.c6(a)
return A.dP(J.a2(a))},
c6(a){var s=a[v.arrayRti],r=t.b
if(s==null)return r
if(s.constructor!==r.constructor)return r
return s},
x(a){var s=a.$ti
return s!=null?s:A.dP(a)},
dP(a){var s=a.constructor,r=s.$ccache
if(r!=null)return r
return A.ht(a,s)},
ht(a,b){var s=a instanceof A.O?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,r=A.hf(v.typeUniverse,s.name)
b.$ccache=r
return r},
ib(a){var s,r=v.types,q=r[a]
if(typeof q=="string"){s=A.c5(v.typeUniverse,q,!1)
r[a]=s
return s}return q},
ia(a){return A.T(A.x(a))},
hN(a){var s=a instanceof A.O?A.eX(a):null
if(s!=null)return s
if(t.R.b(a))return J.e4(a).a
if(Array.isArray(a))return A.c6(a)
return A.ar(a)},
T(a){var s=a.r
return s==null?a.r=A.eG(a):s},
eG(a){var s,r,q=a.as,p=q.replace(/\*/g,"")
if(p===q)return a.r=new A.d5(a)
s=A.c5(v.typeUniverse,p,!0)
r=s.r
return r==null?s.r=A.eG(s):r},
z(a){return A.T(A.c5(v.typeUniverse,a,!1))},
hs(a){var s,r,q,p,o,n,m=this
if(m===t.K)return A.L(m,a,A.hz)
if(!A.M(m))s=m===t._
else s=!0
if(s)return A.L(m,a,A.hD)
s=m.w
if(s===7)return A.L(m,a,A.hq)
if(s===1)return A.L(m,a,A.eM)
r=s===6?m.x:m
q=r.w
if(q===8)return A.L(m,a,A.hv)
if(r===t.S)p=A.eL
else if(r===t.i||r===t.n)p=A.hy
else if(r===t.N)p=A.hB
else p=r===t.y?A.db:null
if(p!=null)return A.L(m,a,p)
if(q===9){o=r.x
if(r.y.every(A.ih)){m.f="$i"+o
if(o==="j")return A.L(m,a,A.hx)
return A.L(m,a,A.hC)}}else if(q===11){n=A.i0(r.x,r.y)
return A.L(m,a,n==null?A.eM:n)}return A.L(m,a,A.ho)},
L(a,b,c){a.b=c
return a.b(b)},
hr(a){var s,r=this,q=A.hn
if(!A.M(r))s=r===t._
else s=!0
if(s)q=A.hj
else if(r===t.K)q=A.hh
else{s=A.b8(r)
if(s)q=A.hp}r.a=q
return r.a(a)},
cc(a){var s=a.w,r=!0
if(!A.M(a))if(!(a===t._))if(!(a===t.F))if(s!==7)if(!(s===6&&A.cc(a.x)))r=s===8&&A.cc(a.x)||a===t.P||a===t.T
return r},
ho(a){var s=this
if(a==null)return A.cc(s)
return A.ii(v.typeUniverse,A.ig(a,s),s)},
hq(a){if(a==null)return!0
return this.x.b(a)},
hC(a){var s,r=this
if(a==null)return A.cc(r)
s=r.f
if(a instanceof A.c)return!!a[s]
return!!J.a2(a)[s]},
hx(a){var s,r=this
if(a==null)return A.cc(r)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
s=r.f
if(a instanceof A.c)return!!a[s]
return!!J.a2(a)[s]},
hn(a){var s=this
if(a==null){if(A.b8(s))return a}else if(s.b(a))return a
A.eH(a,s)},
hp(a){var s=this
if(a==null)return a
else if(s.b(a))return a
A.eH(a,s)},
eH(a,b){throw A.b(A.h5(A.es(a,A.u(b,null))))},
es(a,b){return A.cf(a)+": type '"+A.u(A.hN(a),null)+"' is not a subtype of type '"+b+"'"},
h5(a){return new A.b1("TypeError: "+a)},
t(a,b){return new A.b1("TypeError: "+A.es(a,b))},
hv(a){var s=this,r=s.w===6?s.x:s
return r.x.b(a)||A.dG(v.typeUniverse,r).b(a)},
hz(a){return a!=null},
hh(a){if(a!=null)return a
throw A.b(A.t(a,"Object"))},
hD(a){return!0},
hj(a){return a},
eM(a){return!1},
db(a){return!0===a||!1===a},
iM(a){if(!0===a)return!0
if(!1===a)return!1
throw A.b(A.t(a,"bool"))},
iO(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.b(A.t(a,"bool"))},
iN(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.b(A.t(a,"bool?"))},
iP(a){if(typeof a=="number")return a
throw A.b(A.t(a,"double"))},
iR(a){if(typeof a=="number")return a
if(a==null)return a
throw A.b(A.t(a,"double"))},
iQ(a){if(typeof a=="number")return a
if(a==null)return a
throw A.b(A.t(a,"double?"))},
eL(a){return typeof a=="number"&&Math.floor(a)===a},
iS(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.b(A.t(a,"int"))},
iU(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.b(A.t(a,"int"))},
iT(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.b(A.t(a,"int?"))},
hy(a){return typeof a=="number"},
iV(a){if(typeof a=="number")return a
throw A.b(A.t(a,"num"))},
iX(a){if(typeof a=="number")return a
if(a==null)return a
throw A.b(A.t(a,"num"))},
iW(a){if(typeof a=="number")return a
if(a==null)return a
throw A.b(A.t(a,"num?"))},
hB(a){return typeof a=="string"},
hi(a){if(typeof a=="string")return a
throw A.b(A.t(a,"String"))},
iZ(a){if(typeof a=="string")return a
if(a==null)return a
throw A.b(A.t(a,"String"))},
iY(a){if(typeof a=="string")return a
if(a==null)return a
throw A.b(A.t(a,"String?"))},
eS(a,b){var s,r,q
for(s="",r="",q=0;q<a.length;++q,r=", ")s+=r+A.u(a[q],b)
return s},
hJ(a,b){var s,r,q,p,o,n,m=a.x,l=a.y
if(""===m)return"("+A.eS(l,b)+")"
s=l.length
r=m.split(",")
q=r.length-s
for(p="(",o="",n=0;n<s;++n,o=", "){p+=o
if(q===0)p+="{"
p+=A.u(l[n],b)
if(q>=0)p+=" "+r[q];++q}return p+"})"},
eI(a3,a4,a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=", ",a2=null
if(a5!=null){s=a5.length
if(a4==null)a4=A.an([],t.s)
else a2=a4.length
r=a4.length
for(q=s;q>0;--q)a4.push("T"+(r+q))
for(p=t.X,o=t._,n="<",m="",q=0;q<s;++q,m=a1){n=B.i.aQ(n+m,a4[a4.length-1-q])
l=a5[q]
k=l.w
if(!(k===2||k===3||k===4||k===5||l===p))j=l===o
else j=!0
if(!j)n+=" extends "+A.u(l,a4)}n+=">"}else n=""
p=a3.x
i=a3.y
h=i.a
g=h.length
f=i.b
e=f.length
d=i.c
c=d.length
b=A.u(p,a4)
for(a="",a0="",q=0;q<g;++q,a0=a1)a+=a0+A.u(h[q],a4)
if(e>0){a+=a0+"["
for(a0="",q=0;q<e;++q,a0=a1)a+=a0+A.u(f[q],a4)
a+="]"}if(c>0){a+=a0+"{"
for(a0="",q=0;q<c;q+=3,a0=a1){a+=a0
if(d[q+1])a+="required "
a+=A.u(d[q+2],a4)+" "+d[q]}a+="}"}if(a2!=null){a4.toString
a4.length=a2}return n+"("+a+") => "+b},
u(a,b){var s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6)return A.u(a.x,b)
if(m===7){s=a.x
r=A.u(s,b)
q=s.w
return(q===12||q===13?"("+r+")":r)+"?"}if(m===8)return"FutureOr<"+A.u(a.x,b)+">"
if(m===9){p=A.hQ(a.x)
o=a.y
return o.length>0?p+("<"+A.eS(o,b)+">"):p}if(m===11)return A.hJ(a,b)
if(m===12)return A.eI(a,b,null)
if(m===13)return A.eI(a.x,b,a.y)
if(m===14){n=a.x
return b[b.length-1-n]}return"?"},
hQ(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
hg(a,b){var s=a.tR[b]
for(;typeof s=="string";)s=a.tR[s]
return s},
hf(a,b){var s,r,q,p,o,n=a.eT,m=n[b]
if(m==null)return A.c5(a,b,!1)
else if(typeof m=="number"){s=m
r=A.b4(a,5,"#")
q=A.d7(s)
for(p=0;p<s;++p)q[p]=r
o=A.b3(a,b,q)
n[b]=o
return o}else return m},
hd(a,b){return A.eE(a.tR,b)},
hc(a,b){return A.eE(a.eT,b)},
c5(a,b,c){var s,r=a.eC,q=r.get(b)
if(q!=null)return q
s=A.ey(A.ew(a,null,b,c))
r.set(b,s)
return s},
d6(a,b,c){var s,r,q=b.z
if(q==null)q=b.z=new Map()
s=q.get(c)
if(s!=null)return s
r=A.ey(A.ew(a,b,c,!0))
q.set(c,r)
return r},
he(a,b,c){var s,r,q,p=b.Q
if(p==null)p=b.Q=new Map()
s=c.as
r=p.get(s)
if(r!=null)return r
q=A.dM(a,b,c.w===10?c.y:[c])
p.set(s,q)
return q},
K(a,b){b.a=A.hr
b.b=A.hs
return b},
b4(a,b,c){var s,r,q=a.eC.get(c)
if(q!=null)return q
s=new A.w(null,null)
s.w=b
s.as=c
r=A.K(a,s)
a.eC.set(c,r)
return r},
eD(a,b,c){var s,r=b.as+"*",q=a.eC.get(r)
if(q!=null)return q
s=A.ha(a,b,r,c)
a.eC.set(r,s)
return s},
ha(a,b,c,d){var s,r,q
if(d){s=b.w
if(!A.M(b))r=b===t.P||b===t.T||s===7||s===6
else r=!0
if(r)return b}q=new A.w(null,null)
q.w=6
q.x=b
q.as=c
return A.K(a,q)},
dO(a,b,c){var s,r=b.as+"?",q=a.eC.get(r)
if(q!=null)return q
s=A.h9(a,b,r,c)
a.eC.set(r,s)
return s},
h9(a,b,c,d){var s,r,q,p
if(d){s=b.w
r=!0
if(!A.M(b))if(!(b===t.P||b===t.T))if(s!==7)r=s===8&&A.b8(b.x)
if(r)return b
else if(s===1||b===t.F)return t.P
else if(s===6){q=b.x
if(q.w===8&&A.b8(q.x))return q
else return A.ej(a,b)}}p=new A.w(null,null)
p.w=7
p.x=b
p.as=c
return A.K(a,p)},
eB(a,b,c){var s,r=b.as+"/",q=a.eC.get(r)
if(q!=null)return q
s=A.h7(a,b,r,c)
a.eC.set(r,s)
return s},
h7(a,b,c,d){var s,r
if(d){s=b.w
if(A.M(b)||b===t.K||b===t._)return b
else if(s===1)return A.b3(a,"F",[b])
else if(b===t.P||b===t.T)return t.bc}r=new A.w(null,null)
r.w=8
r.x=b
r.as=c
return A.K(a,r)},
hb(a,b){var s,r,q=""+b+"^",p=a.eC.get(q)
if(p!=null)return p
s=new A.w(null,null)
s.w=14
s.x=b
s.as=q
r=A.K(a,s)
a.eC.set(q,r)
return r},
b2(a){var s,r,q,p=a.length
for(s="",r="",q=0;q<p;++q,r=",")s+=r+a[q].as
return s},
h6(a){var s,r,q,p,o,n=a.length
for(s="",r="",q=0;q<n;q+=3,r=","){p=a[q]
o=a[q+1]?"!":":"
s+=r+p+o+a[q+2].as}return s},
b3(a,b,c){var s,r,q,p=b
if(c.length>0)p+="<"+A.b2(c)+">"
s=a.eC.get(p)
if(s!=null)return s
r=new A.w(null,null)
r.w=9
r.x=b
r.y=c
if(c.length>0)r.c=c[0]
r.as=p
q=A.K(a,r)
a.eC.set(p,q)
return q},
dM(a,b,c){var s,r,q,p,o,n
if(b.w===10){s=b.x
r=b.y.concat(c)}else{r=c
s=b}q=s.as+(";<"+A.b2(r)+">")
p=a.eC.get(q)
if(p!=null)return p
o=new A.w(null,null)
o.w=10
o.x=s
o.y=r
o.as=q
n=A.K(a,o)
a.eC.set(q,n)
return n},
eC(a,b,c){var s,r,q="+"+(b+"("+A.b2(c)+")"),p=a.eC.get(q)
if(p!=null)return p
s=new A.w(null,null)
s.w=11
s.x=b
s.y=c
s.as=q
r=A.K(a,s)
a.eC.set(q,r)
return r},
eA(a,b,c){var s,r,q,p,o,n=b.as,m=c.a,l=m.length,k=c.b,j=k.length,i=c.c,h=i.length,g="("+A.b2(m)
if(j>0){s=l>0?",":""
g+=s+"["+A.b2(k)+"]"}if(h>0){s=l>0?",":""
g+=s+"{"+A.h6(i)+"}"}r=n+(g+")")
q=a.eC.get(r)
if(q!=null)return q
p=new A.w(null,null)
p.w=12
p.x=b
p.y=c
p.as=r
o=A.K(a,p)
a.eC.set(r,o)
return o},
dN(a,b,c,d){var s,r=b.as+("<"+A.b2(c)+">"),q=a.eC.get(r)
if(q!=null)return q
s=A.h8(a,b,c,r,d)
a.eC.set(r,s)
return s},
h8(a,b,c,d,e){var s,r,q,p,o,n,m,l
if(e){s=c.length
r=A.d7(s)
for(q=0,p=0;p<s;++p){o=c[p]
if(o.w===1){r[p]=o;++q}}if(q>0){n=A.S(a,b,r,0)
m=A.ao(a,c,r,0)
return A.dN(a,n,m,c!==m)}}l=new A.w(null,null)
l.w=13
l.x=b
l.y=c
l.as=d
return A.K(a,l)},
ew(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
ey(a){var s,r,q,p,o,n,m,l=a.r,k=a.s
for(s=l.length,r=0;r<s;){q=l.charCodeAt(r)
if(q>=48&&q<=57)r=A.h_(r+1,q,l,k)
else if((((q|32)>>>0)-97&65535)<26||q===95||q===36||q===124)r=A.ex(a,r,l,k,!1)
else if(q===46)r=A.ex(a,r,l,k,!0)
else{++r
switch(q){case 44:break
case 58:k.push(!1)
break
case 33:k.push(!0)
break
case 59:k.push(A.R(a.u,a.e,k.pop()))
break
case 94:k.push(A.hb(a.u,k.pop()))
break
case 35:k.push(A.b4(a.u,5,"#"))
break
case 64:k.push(A.b4(a.u,2,"@"))
break
case 126:k.push(A.b4(a.u,3,"~"))
break
case 60:k.push(a.p)
a.p=k.length
break
case 62:A.h1(a,k)
break
case 38:A.h0(a,k)
break
case 42:p=a.u
k.push(A.eD(p,A.R(p,a.e,k.pop()),a.n))
break
case 63:p=a.u
k.push(A.dO(p,A.R(p,a.e,k.pop()),a.n))
break
case 47:p=a.u
k.push(A.eB(p,A.R(p,a.e,k.pop()),a.n))
break
case 40:k.push(-3)
k.push(a.p)
a.p=k.length
break
case 41:A.fZ(a,k)
break
case 91:k.push(a.p)
a.p=k.length
break
case 93:o=k.splice(a.p)
A.ez(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-1)
break
case 123:k.push(a.p)
a.p=k.length
break
case 125:o=k.splice(a.p)
A.h3(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-2)
break
case 43:n=l.indexOf("(",r)
k.push(l.substring(r,n))
k.push(-4)
k.push(a.p)
a.p=k.length
r=n+1
break
default:throw"Bad character "+q}}}m=k.pop()
return A.R(a.u,a.e,m)},
h_(a,b,c,d){var s,r,q=b-48
for(s=c.length;a<s;++a){r=c.charCodeAt(a)
if(!(r>=48&&r<=57))break
q=q*10+(r-48)}d.push(q)
return a},
ex(a,b,c,d,e){var s,r,q,p,o,n,m=b+1
for(s=c.length;m<s;++m){r=c.charCodeAt(m)
if(r===46){if(e)break
e=!0}else{if(!((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124))q=r>=48&&r<=57
else q=!0
if(!q)break}}p=c.substring(b,m)
if(e){s=a.u
o=a.e
if(o.w===10)o=o.x
n=A.hg(s,o.x)[p]
if(n==null)A.a4('No "'+p+'" in "'+A.fQ(o)+'"')
d.push(A.d6(s,o,n))}else d.push(p)
return m},
h1(a,b){var s,r=a.u,q=A.ev(a,b),p=b.pop()
if(typeof p=="string")b.push(A.b3(r,p,q))
else{s=A.R(r,a.e,p)
switch(s.w){case 12:b.push(A.dN(r,s,q,a.n))
break
default:b.push(A.dM(r,s,q))
break}}},
fZ(a,b){var s,r,q,p=a.u,o=b.pop(),n=null,m=null
if(typeof o=="number")switch(o){case-1:n=b.pop()
break
case-2:m=b.pop()
break
default:b.push(o)
break}else b.push(o)
s=A.ev(a,b)
o=b.pop()
switch(o){case-3:o=b.pop()
if(n==null)n=p.sEA
if(m==null)m=p.sEA
r=A.R(p,a.e,o)
q=new A.c_()
q.a=s
q.b=n
q.c=m
b.push(A.eA(p,r,q))
return
case-4:b.push(A.eC(p,b.pop(),s))
return
default:throw A.b(A.bd("Unexpected state under `()`: "+A.p(o)))}},
h0(a,b){var s=b.pop()
if(0===s){b.push(A.b4(a.u,1,"0&"))
return}if(1===s){b.push(A.b4(a.u,4,"1&"))
return}throw A.b(A.bd("Unexpected extended operation "+A.p(s)))},
ev(a,b){var s=b.splice(a.p)
A.ez(a.u,a.e,s)
a.p=b.pop()
return s},
R(a,b,c){if(typeof c=="string")return A.b3(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.h2(a,b,c)}else return c},
ez(a,b,c){var s,r=c.length
for(s=0;s<r;++s)c[s]=A.R(a,b,c[s])},
h3(a,b,c){var s,r=c.length
for(s=2;s<r;s+=3)c[s]=A.R(a,b,c[s])},
h2(a,b,c){var s,r,q=b.w
if(q===10){if(c===0)return b.x
s=b.y
r=s.length
if(c<=r)return s[c-1]
c-=r
b=b.x
q=b.w}else if(c===0)return b
if(q!==9)throw A.b(A.bd("Indexed base must be an interface type"))
s=b.y
if(c<=s.length)return s[c-1]
throw A.b(A.bd("Bad index "+c+" for "+b.i(0)))},
ii(a,b,c){var s,r=b.d
if(r==null)r=b.d=new Map()
s=r.get(c)
if(s==null){s=A.n(a,b,null,c,null,!1)?1:0
r.set(c,s)}if(0===s)return!1
if(1===s)return!0
return!0},
n(a,b,c,d,e,f){var s,r,q,p,o,n,m,l,k,j,i
if(b===d)return!0
if(!A.M(d))s=d===t._
else s=!0
if(s)return!0
r=b.w
if(r===4)return!0
if(A.M(b))return!1
s=b.w
if(s===1)return!0
q=r===14
if(q)if(A.n(a,c[b.x],c,d,e,!1))return!0
p=d.w
s=b===t.P||b===t.T
if(s){if(p===8)return A.n(a,b,c,d.x,e,!1)
return d===t.P||d===t.T||p===7||p===6}if(d===t.K){if(r===8)return A.n(a,b.x,c,d,e,!1)
if(r===6)return A.n(a,b.x,c,d,e,!1)
return r!==7}if(r===6)return A.n(a,b.x,c,d,e,!1)
if(p===6){s=A.ej(a,d)
return A.n(a,b,c,s,e,!1)}if(r===8){if(!A.n(a,b.x,c,d,e,!1))return!1
return A.n(a,A.dG(a,b),c,d,e,!1)}if(r===7){s=A.n(a,t.P,c,d,e,!1)
return s&&A.n(a,b.x,c,d,e,!1)}if(p===8){if(A.n(a,b,c,d.x,e,!1))return!0
return A.n(a,b,c,A.dG(a,d),e,!1)}if(p===7){s=A.n(a,b,c,t.P,e,!1)
return s||A.n(a,b,c,d.x,e,!1)}if(q)return!1
s=r!==12
if((!s||r===13)&&d===t.Z)return!0
o=r===11
if(o&&d===t.L)return!0
if(p===13){if(b===t.g)return!0
if(r!==13)return!1
n=b.y
m=d.y
l=n.length
if(l!==m.length)return!1
c=c==null?n:n.concat(c)
e=e==null?m:m.concat(e)
for(k=0;k<l;++k){j=n[k]
i=m[k]
if(!A.n(a,j,c,i,e,!1)||!A.n(a,i,e,j,c,!1))return!1}return A.eK(a,b.x,c,d.x,e,!1)}if(p===12){if(b===t.g)return!0
if(s)return!1
return A.eK(a,b,c,d,e,!1)}if(r===9){if(p!==9)return!1
return A.hw(a,b,c,d,e,!1)}if(o&&p===11)return A.hA(a,b,c,d,e,!1)
return!1},
eK(a3,a4,a5,a6,a7,a8){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2
if(!A.n(a3,a4.x,a5,a6.x,a7,!1))return!1
s=a4.y
r=a6.y
q=s.a
p=r.a
o=q.length
n=p.length
if(o>n)return!1
m=n-o
l=s.b
k=r.b
j=l.length
i=k.length
if(o+j<n+i)return!1
for(h=0;h<o;++h){g=q[h]
if(!A.n(a3,p[h],a7,g,a5,!1))return!1}for(h=0;h<m;++h){g=l[h]
if(!A.n(a3,p[o+h],a7,g,a5,!1))return!1}for(h=0;h<i;++h){g=l[m+h]
if(!A.n(a3,k[h],a7,g,a5,!1))return!1}f=s.c
e=r.c
d=f.length
c=e.length
for(b=0,a=0;a<c;a+=3){a0=e[a]
for(;!0;){if(b>=d)return!1
a1=f[b]
b+=3
if(a0<a1)return!1
a2=f[b-2]
if(a1<a0){if(a2)return!1
continue}g=e[a+1]
if(a2&&!g)return!1
g=f[b-1]
if(!A.n(a3,e[a+2],a7,g,a5,!1))return!1
break}}for(;b<d;){if(f[b+1])return!1
b+=3}return!0},
hw(a,b,c,d,e,f){var s,r,q,p,o,n=b.x,m=d.x
for(;n!==m;){s=a.tR[n]
if(s==null)return!1
if(typeof s=="string"){n=s
continue}r=s[m]
if(r==null)return!1
q=r.length
p=q>0?new Array(q):v.typeUniverse.sEA
for(o=0;o<q;++o)p[o]=A.d6(a,b,r[o])
return A.eF(a,p,null,c,d.y,e,!1)}return A.eF(a,b.y,null,c,d.y,e,!1)},
eF(a,b,c,d,e,f,g){var s,r=b.length
for(s=0;s<r;++s)if(!A.n(a,b[s],d,e[s],f,!1))return!1
return!0},
hA(a,b,c,d,e,f){var s,r=b.y,q=d.y,p=r.length
if(p!==q.length)return!1
if(b.x!==d.x)return!1
for(s=0;s<p;++s)if(!A.n(a,r[s],c,q[s],e,!1))return!1
return!0},
b8(a){var s=a.w,r=!0
if(!(a===t.P||a===t.T))if(!A.M(a))if(s!==7)if(!(s===6&&A.b8(a.x)))r=s===8&&A.b8(a.x)
return r},
ih(a){var s
if(!A.M(a))s=a===t._
else s=!0
return s},
M(a){var s=a.w
return s===2||s===3||s===4||s===5||a===t.X},
eE(a,b){var s,r,q=Object.keys(b),p=q.length
for(s=0;s<p;++s){r=q[s]
a[r]=b[r]}},
d7(a){return a>0?new Array(a):v.typeUniverse.sEA},
w:function w(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
c_:function c_(){this.c=this.b=this.a=null},
d5:function d5(a){this.a=a},
bZ:function bZ(){},
b1:function b1(a){this.a=a},
fT(){var s,r,q={}
if(self.scheduleImmediate!=null)return A.hS()
if(self.MutationObserver!=null&&self.document!=null){s=self.document.createElement("div")
r=self.document.createElement("span")
q.a=null
new self.MutationObserver(A.b7(new A.cE(q),1)).observe(s,{childList:true})
return new A.cD(q,s,r)}else if(self.setImmediate!=null)return A.hT()
return A.hU()},
fU(a){self.scheduleImmediate(A.b7(new A.cF(a),0))},
fV(a){self.setImmediate(A.b7(new A.cG(a),0))},
fW(a){A.dI(B.c,a)},
dI(a,b){return A.h4(0,b)},
h4(a,b){var s=new A.d3()
s.aX(a,b)
return s},
cb(a){return new A.bS(new A.i($.f,a.h("i<0>")),a.h("bS<0>"))},
ca(a,b){a.$2(0,null)
b.b=!0
return b.a},
c7(a,b){A.hk(a,b)},
c9(a,b){b.E(a)},
c8(a,b){b.P(A.D(a),A.y(a))},
hk(a,b){var s,r,q=new A.d9(b),p=new A.da(b)
if(a instanceof A.i)a.az(q,p,t.z)
else{s=t.z
if(a instanceof A.i)a.Y(q,p,s)
else{r=new A.i($.f,t.c)
r.a=8
r.c=a
r.az(q,p,s)}}},
cd(a){var s=function(b,c){return function(d,e){while(true){try{b(d,e)
break}catch(r){e=r
d=c}}}}(a,1)
return $.f.W(new A.dd(s))},
ce(a,b){var s=A.aq(a,"error",t.K)
return new A.be(s,b==null?A.dA(a):b)},
dA(a){var s
if(t.Q.b(a)){s=a.gJ()
if(s!=null)return s}return B.e},
eb(a,b){var s,r=!b.b(null)
if(r)throw A.b(A.dz(null,"computation","The type parameter is not nullable"))
s=new A.i($.f,b.h("i<0>"))
A.fS(a,new A.ci(null,s,b))
return s},
et(a,b){var s,r
for(;s=a.a,(s&4)!==0;)a=a.c
if(a===b){b.L(new A.E(!0,a,null,"Cannot complete a future with itself"),A.el())
return}s|=b.a&1
a.a=s
if((s&24)!==0){r=b.N()
b.M(a)
A.ah(b,r)}else{r=b.c
b.aw(a)
a.aa(r)}},
fX(a,b){var s,r,q={},p=q.a=a
for(;s=p.a,(s&4)!==0;){p=p.c
q.a=p}if(p===b){b.L(new A.E(!0,p,null,"Cannot complete a future with itself"),A.el())
return}if((s&24)===0){r=b.c
b.aw(p)
q.a.aa(r)
return}if((s&16)===0&&b.c==null){b.M(p)
return}b.a^=2
A.am(null,null,b.b,new A.cQ(q,b))},
ah(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g={},f=g.a=a
for(;!0;){s={}
r=f.a
q=(r&16)===0
p=!q
if(b==null){if(p&&(r&1)===0){f=f.c
A.al(f.a,f.b)}return}s.a=b
o=b.a
for(f=b;o!=null;f=o,o=n){f.a=null
A.ah(g.a,f)
s.a=o
n=o.a}r=g.a
m=r.c
s.b=p
s.c=m
if(q){l=f.c
l=(l&1)!==0||(l&15)===8}else l=!0
if(l){k=f.b.b
if(p){r=r.b===k
r=!(r||r)}else r=!1
if(r){A.al(m.a,m.b)
return}j=$.f
if(j!==k)$.f=k
else j=null
f=f.c
if((f&15)===8)new A.cX(s,g,p).$0()
else if(q){if((f&1)!==0)new A.cW(s,m).$0()}else if((f&2)!==0)new A.cV(g,s).$0()
if(j!=null)$.f=j
f=s.c
if(f instanceof A.i){r=s.a.$ti
r=r.h("F<2>").b(f)||!r.y[1].b(f)}else r=!1
if(r){i=s.a.b
if((f.a&24)!==0){h=i.c
i.c=null
b=i.O(h)
i.a=f.a&30|i.a&1
i.c=f.c
g.a=f
continue}else A.et(f,i)
return}}i=s.a.b
h=i.c
i.c=null
b=i.O(h)
f=s.b
r=s.c
if(!f){i.a=8
i.c=r}else{i.a=i.a&1|16
i.c=r}g.a=i
f=i}},
hK(a,b){if(t.C.b(a))return b.W(a)
if(t.v.b(a))return a
throw A.b(A.dz(a,"onError",u.c))},
hF(){var s,r
for(s=$.ak;s!=null;s=$.ak){$.b6=null
r=s.b
$.ak=r
if(r==null)$.b5=null
s.a.$0()}},
hM(){$.dQ=!0
try{A.hF()}finally{$.b6=null
$.dQ=!1
if($.ak!=null)$.e1().$1(A.eW())}},
eU(a){var s=new A.bT(a),r=$.b5
if(r==null){$.ak=$.b5=s
if(!$.dQ)$.e1().$1(A.eW())}else $.b5=r.b=s},
hL(a){var s,r,q,p=$.ak
if(p==null){A.eU(a)
$.b6=$.b5
return}s=new A.bT(a)
r=$.b6
if(r==null){s.b=p
$.ak=$.b6=s}else{q=r.b
s.b=q
$.b6=r.b=s
if(q==null)$.b5=s}},
e0(a){var s=null,r=$.f
if(B.a===r){A.am(s,s,B.a,a)
return}A.am(s,s,r,r.ae(a))},
iA(a,b){A.aq(a,"stream",t.K)
return new A.c3(b.h("c3<0>"))},
em(a){return new A.aQ(null,null,a.h("aQ<0>"))},
eT(a){return},
eq(a,b){return b==null?A.hV():b},
er(a,b){if(b==null)b=A.hX()
if(t.k.b(b))return a.W(b)
if(t.u.b(b))return b
throw A.b(A.N(u.h,null))},
hG(a){},
hI(a,b){A.al(a,b)},
hH(){},
fS(a,b){var s=$.f
if(s===B.a)return A.dI(a,b)
return A.dI(a,s.ae(b))},
al(a,b){A.hL(new A.dc(a,b))},
eP(a,b,c,d){var s,r=$.f
if(r===c)return d.$0()
$.f=c
s=r
try{r=d.$0()
return r}finally{$.f=s}},
eR(a,b,c,d,e){var s,r=$.f
if(r===c)return d.$1(e)
$.f=c
s=r
try{r=d.$1(e)
return r}finally{$.f=s}},
eQ(a,b,c,d,e,f){var s,r=$.f
if(r===c)return d.$2(e,f)
$.f=c
s=r
try{r=d.$2(e,f)
return r}finally{$.f=s}},
am(a,b,c,d){if(B.a!==c)d=c.ae(d)
A.eU(d)},
cE:function cE(a){this.a=a},
cD:function cD(a,b,c){this.a=a
this.b=b
this.c=c},
cF:function cF(a){this.a=a},
cG:function cG(a){this.a=a},
d3:function d3(){},
d4:function d4(a,b){this.a=a
this.b=b},
bS:function bS(a,b){this.a=a
this.b=!1
this.$ti=b},
d9:function d9(a){this.a=a},
da:function da(a){this.a=a},
dd:function dd(a){this.a=a},
be:function be(a,b){this.a=a
this.b=b},
ae:function ae(a,b){this.a=a
this.$ti=b},
af:function af(a,b,c,d,e,f,g){var _=this
_.ay=0
_.CW=_.ch=null
_.w=a
_.a=b
_.b=c
_.c=d
_.d=e
_.e=f
_.r=_.f=null
_.$ti=g},
bU:function bU(){},
aQ:function aQ(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.r=_.e=_.d=null
_.$ti=c},
ci:function ci(a,b,c){this.a=a
this.b=b
this.c=c},
bV:function bV(){},
C:function C(a,b){this.a=a
this.$ti=b},
ag:function ag(a,b,c,d,e){var _=this
_.a=null
_.b=a
_.c=b
_.d=c
_.e=d
_.$ti=e},
i:function i(a,b){var _=this
_.a=0
_.b=a
_.c=null
_.$ti=b},
cN:function cN(a,b){this.a=a
this.b=b},
cU:function cU(a,b){this.a=a
this.b=b},
cR:function cR(a){this.a=a},
cS:function cS(a){this.a=a},
cT:function cT(a,b,c){this.a=a
this.b=b
this.c=c},
cQ:function cQ(a,b){this.a=a
this.b=b},
cP:function cP(a,b){this.a=a
this.b=b},
cO:function cO(a,b,c){this.a=a
this.b=b
this.c=c},
cX:function cX(a,b,c){this.a=a
this.b=b
this.c=c},
cY:function cY(a){this.a=a},
cW:function cW(a,b){this.a=a
this.b=b},
cV:function cV(a,b){this.a=a
this.b=b},
bT:function bT(a){this.a=a
this.b=null},
B:function B(){},
cv:function cv(a,b){this.a=a
this.b=b},
cw:function cw(a,b){this.a=a
this.b=b},
aS:function aS(){},
aT:function aT(){},
aR:function aR(){},
cI:function cI(a,b,c){this.a=a
this.b=b
this.c=c},
cH:function cH(a){this.a=a},
aj:function aj(){},
bY:function bY(){},
bX:function bX(a,b){this.b=a
this.a=null
this.$ti=b},
cK:function cK(a,b){this.b=a
this.c=b
this.a=null},
cJ:function cJ(){},
c2:function c2(a){var _=this
_.a=0
_.c=_.b=null
_.$ti=a},
d0:function d0(a,b){this.a=a
this.b=b},
aU:function aU(a,b){var _=this
_.a=1
_.b=a
_.c=null
_.$ti=b},
c3:function c3(a){this.$ti=a},
d8:function d8(){},
dc:function dc(a,b){this.a=a
this.b=b},
d1:function d1(){},
d2:function d2(a,b){this.a=a
this.b=b},
eu(a,b){var s=a[b]
return s===a?null:s},
dL(a,b,c){if(c==null)a[b]=a
else a[b]=c},
dK(){var s=Object.create(null)
A.dL(s,"<non-identifier-key>",s)
delete s["<non-identifier-key>"]
return s},
bw(a,b,c){return A.i4(a,new A.W(b.h("@<0>").t(c).h("W<1,2>")))},
dF(a,b){return new A.W(a.h("@<0>").t(b).h("W<1,2>"))},
eg(a){var s,r={}
if(A.dX(a))return"{...}"
s=new A.bN("")
try{$.a5.push(a)
s.a+="{"
r.a=!0
a.S(0,new A.cr(r,s))
s.a+="}"}finally{$.a5.pop()}r=s.a
return r.charCodeAt(0)==0?r:r},
aV:function aV(){},
ai:function ai(a){var _=this
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=a},
aW:function aW(a,b){this.a=a
this.$ti=b},
c0:function c0(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
m:function m(){},
X:function X(){},
cr:function cr(a,b){this.a=a
this.b=b},
fs(a,b){a=A.b(a)
a.stack=b.i(0)
throw a
throw A.b("unreachable")},
fD(a,b,c,d){var s,r=c?J.fA(a,d):J.fz(a,d)
if(a!==0&&b!=null)for(s=0;s<r.length;++s)r[s]=b
return r},
ef(a,b,c){var s=A.fC(a,c)
return s},
fC(a,b){var s,r=A.an([],b.h("r<0>"))
for(s=a.gq(a);s.n();)r.push(s.gp())
return r},
en(a,b,c){var s=J.fj(b)
if(!s.n())return a
if(c.length===0){do a+=A.p(s.gp())
while(s.n())}else{a+=A.p(s.gp())
for(;s.n();)a=a+c+A.p(s.gp())}return a},
el(){return A.y(new Error())},
fr(a){var s=Math.abs(a),r=a<0?"-":""
if(s>=1000)return""+a
if(s>=100)return r+"0"+s
if(s>=10)return r+"00"+s
return r+"000"+s},
ea(a){if(a>=100)return""+a
if(a>=10)return"0"+a
return"00"+a},
bj(a){if(a>=10)return""+a
return"0"+a},
cf(a){if(typeof a=="number"||A.db(a)||a==null)return J.a6(a)
if(typeof a=="string")return JSON.stringify(a)
return A.fP(a)},
ft(a,b){A.aq(a,"error",t.K)
A.aq(b,"stackTrace",t.l)
A.fs(a,b)},
bd(a){return new A.bc(a)},
N(a,b){return new A.E(!1,null,b,a)},
dz(a,b,c){return new A.E(!0,a,b,c)},
ei(a,b,c,d,e){return new A.aM(b,c,!0,a,d,"Invalid value")},
fu(a,b,c,d){return new A.bl(b,!0,a,d,"Index out of range")},
dJ(a){return new A.bR(a)},
aO(a){return new A.bP(a)},
dH(a){return new A.Z(a)},
au(a){return new A.bh(a)},
fy(a,b,c){var s,r
if(A.dX(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}s=A.an([],t.s)
$.a5.push(a)
try{A.hE(a,s)}finally{$.a5.pop()}r=A.en(b,s,", ")+c
return r.charCodeAt(0)==0?r:r},
ed(a,b,c){var s,r
if(A.dX(a))return b+"..."+c
s=new A.bN(b)
$.a5.push(a)
try{r=s
r.a=A.en(r.a,a,", ")}finally{$.a5.pop()}s.a+=c
r=s.a
return r.charCodeAt(0)==0?r:r},
hE(a,b){var s,r,q,p,o,n,m,l=a.gq(a),k=0,j=0
while(!0){if(!(k<80||j<3))break
if(!l.n())return
s=A.p(l.gp())
b.push(s)
k+=s.length+2;++j}if(!l.n()){if(j<=5)return
r=b.pop()
q=b.pop()}else{p=l.gp();++j
if(!l.n()){if(j<=4){b.push(A.p(p))
return}r=A.p(p)
q=b.pop()
k+=r.length+2}else{o=l.gp();++j
for(;l.n();p=o,o=n){n=l.gp();++j
if(j>100){while(!0){if(!(k>75&&j>3))break
k-=b.pop().length+2;--j}b.push("...")
return}}q=A.p(p)
r=A.p(o)
k+=r.length+q.length+4}}if(j>b.length+2){k+=5
m="..."}else m=null
while(!0){if(!(k>80&&b.length>3))break
k-=b.pop().length+2
if(m==null){k+=5
m="..."}}if(m!=null)b.push(m)
b.push(q)
b.push(r)},
fF(a,b){var s=B.b.gm(a)
b=B.b.gm(b)
b=A.fR(A.eo(A.eo($.fg(),s),b))
return b},
bi:function bi(a,b,c){this.a=a
this.b=b
this.c=c},
bk:function bk(){},
cL:function cL(){},
k:function k(){},
bc:function bc(a){this.a=a},
I:function I(){},
E:function E(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
aM:function aM(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
bl:function bl(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
bR:function bR(a){this.a=a},
bP:function bP(a){this.a=a},
Z:function Z(a){this.a=a},
bh:function bh(a){this.a=a},
bI:function bI(){},
aN:function aN(){},
cM:function cM(a){this.a=a},
d:function d(){},
ab:function ab(a,b,c){this.a=a
this.b=b
this.$ti=c},
q:function q(){},
c:function c(){},
c4:function c4(a){this.a=a},
bN:function bN(a){this.a=a},
eJ(a){var s
if(typeof a=="function")throw A.b(A.N("Attempting to rewrap a JS function.",null))
s=function(b,c){return function(d){return b(c,d,arguments.length)}}(A.hm,a)
s[$.dw()]=a
return s},
hl(a){return a.$0()},
hm(a,b,c){if(c>=1)return a.$1(b)
return a.$0()},
eO(a){return a==null||A.db(a)||typeof a=="number"||typeof a=="string"||t.U.b(a)||t.W.b(a)||t.M.b(a)||t.O.b(a)||t.G.b(a)||t.e.b(a)||t.I.b(a)||t.E.b(a)||t.q.b(a)||t.J.b(a)||t.Y.b(a)},
dZ(a){if(A.eO(a))return a
return new A.dp(new A.ai(t.A)).$1(a)},
ip(a,b){var s=new A.i($.f,b.h("i<0>")),r=new A.C(s,b.h("C<0>"))
a.then(A.b7(new A.dt(r),1),A.b7(new A.du(r),1))
return s},
eN(a){return a==null||typeof a==="boolean"||typeof a==="number"||typeof a==="string"||a instanceof Int8Array||a instanceof Uint8Array||a instanceof Uint8ClampedArray||a instanceof Int16Array||a instanceof Uint16Array||a instanceof Int32Array||a instanceof Uint32Array||a instanceof Float32Array||a instanceof Float64Array||a instanceof ArrayBuffer||a instanceof DataView},
eY(a){if(A.eN(a))return a
return new A.df(new A.ai(t.A)).$1(a)},
dp:function dp(a){this.a=a},
dt:function dt(a){this.a=a},
du:function du(a){this.a=a},
df:function df(a){this.a=a},
cs:function cs(a){this.a=a},
fx(a,b,c,d){var s=new A.cn(c)
return A.fw(a,s,b,s,c,d)},
cn:function cn(a){this.a=a},
fv(a,b,c,d,e){var s=A.em(d),r=$.f,q=t.j.b(a),p=q?t.r.a(J.e2(a)).gaE():t.m.a(a)
if(q)J.fi(a)
s=new A.ay(p,s,b,c,new A.C(new A.i(r,t.D),t.h),d.h("@<0>").t(e).h("ay<1,2>"))
s.aV(a,b,c,d,e)
return s},
ay:function ay(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.f=e
_.$ti=f},
cm:function cm(a){this.a=a},
bn:function bn(a,b){this.a=a
this.b=b},
bp:function bp(a){this.b=a},
dT(a){if(!t.m.b(a))return a
return A.dS(A.eY(a))},
dS(a){var s,r
if(t.j.b(a)){s=J.dy(a,A.iv(),t.X)
return A.ef(s,!0,s.$ti.h("G.E"))}else if(t.f.b(a)){s=t.z
r=A.dF(s,s)
a.S(0,new A.de(r))
return r}else return A.dT(a)},
b9(a){var s,r
if(a==null)return A.dZ(a)
if(t.j.b(a)){s=J.dy(a,A.iw(),t.X)
return A.ef(s,!0,s.$ti.h("G.E"))}if(t.f.b(a)){s=t.X
return A.dZ(a.bj(0,new A.dq(),s,s))}if(t.B.b(a)){if(typeof a=="function")A.a4(A.N("Attempting to rewrap a JS function.",null))
r=function(b,c){return function(){return b(c)}}(A.hl,a)
r[$.dw()]=a
return r}return A.dZ(a)},
de:function de(a){this.a=a},
dq:function dq(){},
ix(a){A.dY(new A.dv(a),null,t.z,t.j)},
dv:function dv(a){this.a=a},
az:function az(a,b){this.a=a
this.$ti=b},
fY(a,b,c,d){var s=new A.c1(a,A.em(d),c.h("@<0>").t(d).h("c1<1,2>"))
s.aW(a,b,c,d)
return s},
bo:function bo(a,b){this.a=a
this.$ti=b},
c1:function c1(a,b,c){this.a=a
this.c=b
this.$ti=c},
cZ:function cZ(a,b){this.a=a
this.b=b},
dY(a,b,c,d){var s=0,r=A.cb(t.H),q
var $async$dY=A.cd(function(e,f){if(e===1)return A.c8(f,r)
while(true)switch(s){case 0:q=self.self
q=J.e4(q)===B.k?A.fY(t.m.a(q),null,c,d):A.fx(q,null,c,d)
q.gaN().aL(new A.dn(new A.az(new A.bo(q,c.h("@<0>").t(d).h("bo<1,2>")),c.h("@<0>").t(d).h("az<1,2>")),a,d,c))
q.aG()
return A.c9(null,r)}})
return A.ca($async$dY,r)},
dn:function dn(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
dm:function dm(a){this.a=a},
it(a){A.is(new A.bu("Field '"+a+"' has been assigned during initialization."),new Error())},
fw(a,b,c,d,e,f){if(t.j.b(a))t.r.a(J.e2(a)).gaE()
return A.fv(a,c,d,e,f)},
dW(a){var s=0,r=A.cb(t.z),q,p
var $async$dW=A.cd(function(b,c){if(b===1)return A.c8(c,r)
while(true)switch(s){case 0:p=new A.i($.f,t.c)
new A.C(p,t.b3).E(t.Z.a(a[0]).$1(a[1]))
q=p
s=1
break
case 1:return A.c9(q,r)}})
return A.ca($async$dW,r)},
ik(){A.ix($.im)},
i_(a){var s
for(s=0;a>0;){if(B.b.aR(a,2)===0)++s;--a}return s},
a1(a){return A.i3(a)},
i3(a){var s=0,r=A.cb(t.S),q,p
var $async$a1=A.cd(function(b,c){if(b===1)return A.c8(c,r)
while(true)switch(s){case 0:if(a===0){q=0
s=1
break}if(a<=2){q=1
s=1
break}s=3
return A.c7(A.eb(B.c,t.z),$async$a1)
case 3:s=4
return A.c7(A.a1(a-1),$async$a1)
case 4:p=c
s=5
return A.c7(A.a1(a-2),$async$a1)
case 5:q=p+c
s=1
break
case 1:return A.c9(q,r)}})
return A.ca($async$a1,r)},
dh(a){return A.i2(a)},
i2(a){var s=0,r=A.cb(t.S),q,p,o,n,m,l
var $async$dh=A.cd(function(b,c){if(b===1)return A.c8(c,r)
while(true)switch(s){case 0:if(a===0){q=0
s=1
break}if(a<=2){q=1
s=1
break}p=t.z,o=0,n=1,m=1,l=2
case 3:if(!(l<=a)){s=5
break}m=o+n
s=6
return A.c7(A.eb(B.c,p),$async$dh)
case 6:case 4:++l,o=n,n=m
s=3
break
case 5:q=B.b.aO(m)
s=1
break
case 1:return A.c9(q,r)}})
return A.ca($async$dh,r)},
i1(a){var s,r,q,p
if(a===0)return 0
if(a===1||a===2)return 1
for(s=0,r=1,q=1,p=2;p<=a;++p,s=r,r=q)q=s+r
return B.b.aO(q)}},B={}
var w=[A,J,B]
var $={}
A.dD.prototype={}
J.bm.prototype={
B(a,b){return a===b},
gm(a){return A.aL(a)},
i(a){return"Instance of '"+A.bK(a)+"'"},
gl(a){return A.T(A.dP(this))}}
J.bq.prototype={
i(a){return String(a)},
gm(a){return a?519018:218159},
gl(a){return A.T(t.y)},
$ih:1}
J.aB.prototype={
B(a,b){return null==b},
i(a){return"null"},
gm(a){return 0},
$ih:1,
$iq:1}
J.aD.prototype={$io:1}
J.Q.prototype={
gm(a){return 0},
gl(a){return B.k},
i(a){return String(a)}}
J.bJ.prototype={}
J.aP.prototype={}
J.P.prototype={
i(a){var s=a[$.dw()]
if(s==null)return this.aU(a)
return"JavaScript function for "+J.a6(s)},
$iV:1}
J.aC.prototype={
gm(a){return 0},
i(a){return String(a)}}
J.aE.prototype={
gm(a){return 0},
i(a){return String(a)}}
J.r.prototype={
be(a,b){var s
if(!!a.fixed$length)A.a4(A.dJ("addAll"))
for(s=b.gq(b);s.n();)a.push(s.gp())},
T(a,b,c){return new A.H(a,b,A.c6(a).h("@<1>").t(c).h("H<1,2>"))},
R(a,b){return a[b]},
gaF(a){if(a.length>0)return a[0]
throw A.b(A.co())},
gaK(a){var s=a.length
if(s>0)return a[s-1]
throw A.b(A.co())},
i(a){return A.ed(a,"[","]")},
gq(a){return new J.bb(a,a.length,A.c6(a).h("bb<1>"))},
gm(a){return A.aL(a)},
gk(a){return a.length},
j(a,b){if(!(b>=0&&b<a.length))throw A.b(A.eZ(a,b))
return a[b]},
gl(a){return A.T(A.c6(a))},
$ie:1,
$id:1,
$ij:1}
J.cp.prototype={}
J.bb.prototype={
gp(){var s=this.d
return s==null?this.$ti.c.a(s):s},
n(){var s,r=this,q=r.a,p=q.length
if(r.b!==p)throw A.b(A.ir(q))
s=r.c
if(s>=p){r.d=null
return!1}r.d=q[s]
r.c=s+1
return!0}}
J.bs.prototype={
aO(a){if(a>0){if(a!==1/0)return Math.round(a)}else if(a>-1/0)return 0-Math.round(0-a)
throw A.b(A.dJ(""+a+".round()"))},
i(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gm(a){var s,r,q,p,o=a|0
if(a===o)return o&536870911
s=Math.abs(a)
r=Math.log(s)/0.6931471805599453|0
q=Math.pow(2,r)
p=s<1?s/q:q/s
return((p*9007199254740992|0)+(p*3542243181176521|0))*599197+r*1259&536870911},
aR(a,b){var s=a%b
if(s===0)return 0
if(s>0)return s
return s+b},
bc(a,b){var s
if(a>0)s=this.bb(a,b)
else{s=b>31?31:b
s=a>>s>>>0}return s},
bb(a,b){return b>31?0:a>>>b},
gl(a){return A.T(t.n)},
$il:1}
J.aA.prototype={
gl(a){return A.T(t.S)},
$ih:1,
$ia:1}
J.br.prototype={
gl(a){return A.T(t.i)},
$ih:1}
J.a8.prototype={
aQ(a,b){return a+b},
aS(a,b){var s,r
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw A.b(B.r)
for(s=a,r="";!0;){if((b&1)===1)r=s+r
b=b>>>1
if(b===0)break
s+=s}return r},
bl(a,b,c){var s=b-a.length
if(s<=0)return a
return this.aS(c,s)+a},
i(a){return a},
gm(a){var s,r,q
for(s=a.length,r=0,q=0;q<s;++q){r=r+a.charCodeAt(q)&536870911
r=r+((r&524287)<<10)&536870911
r^=r>>6}r=r+((r&67108863)<<3)&536870911
r^=r>>11
return r+((r&16383)<<15)&536870911},
gl(a){return A.T(t.N)},
gk(a){return a.length},
$ih:1,
$ia_:1}
A.as.prototype={
G(a,b,c,d){var s=this.a.aM(null,b,c),r=new A.at(s,$.f,this.$ti.h("at<1,2>"))
s.U(r.gb4())
r.U(a)
r.V(d)
return r},
aL(a){return this.G(a,null,null,null)},
aM(a,b,c){return this.G(a,b,c,null)}}
A.at.prototype={
U(a){this.c=a==null?null:a},
V(a){var s=this
s.a.V(a)
if(a==null)s.d=null
else if(t.k.b(a))s.d=s.b.W(a)
else if(t.u.b(a))s.d=a
else throw A.b(A.N(u.h,null))},
b5(a){var s,r,q,p,o,n=this,m=n.c
if(m==null)return
s=null
try{s=n.$ti.y[1].a(a)}catch(o){r=A.D(o)
q=A.y(o)
p=n.d
if(p==null)A.al(r,q)
else{m=n.b
if(t.k.b(p))m.aP(p,r,q)
else m.X(t.u.a(p),r)}return}n.b.X(m,s)}}
A.bu.prototype={
i(a){return"LateInitializationError: "+this.a}}
A.cu.prototype={}
A.e.prototype={}
A.G.prototype={
gq(a){return new A.a9(this,this.gk(0),this.$ti.h("a9<G.E>"))},
T(a,b,c){return new A.H(this,b,this.$ti.h("@<G.E>").t(c).h("H<1,2>"))}}
A.a9.prototype={
gp(){var s=this.d
return s==null?this.$ti.c.a(s):s},
n(){var s,r=this,q=r.a,p=J.f0(q),o=p.gk(q)
if(r.b!==o)throw A.b(A.au(q))
s=r.c
if(s>=o){r.d=null
return!1}r.d=p.R(q,s);++r.c
return!0}}
A.Y.prototype={
gq(a){var s=this.a
return new A.bx(s.gq(s),this.b,A.x(this).h("bx<1,2>"))},
gk(a){var s=this.a
return s.gk(s)}}
A.av.prototype={$ie:1}
A.bx.prototype={
n(){var s=this,r=s.b
if(r.n()){s.a=s.c.$1(r.gp())
return!0}s.a=null
return!1},
gp(){var s=this.a
return s==null?this.$ti.y[1].a(s):s}}
A.H.prototype={
gk(a){return J.e3(this.a)},
R(a,b){return this.b.$1(J.fh(this.a,b))}}
A.ax.prototype={}
A.cx.prototype={
u(a){var s,r,q=this,p=new RegExp(q.a).exec(a)
if(p==null)return null
s=Object.create(null)
r=q.b
if(r!==-1)s.arguments=p[r+1]
r=q.c
if(r!==-1)s.argumentsExpr=p[r+1]
r=q.d
if(r!==-1)s.expr=p[r+1]
r=q.e
if(r!==-1)s.method=p[r+1]
r=q.f
if(r!==-1)s.receiver=p[r+1]
return s}}
A.aK.prototype={
i(a){return"Null check operator used on a null value"}}
A.bt.prototype={
i(a){var s,r=this,q="NoSuchMethodError: method not found: '",p=r.b
if(p==null)return"NoSuchMethodError: "+r.a
s=r.c
if(s==null)return q+p+"' ("+r.a+")"
return q+p+"' on '"+s+"' ("+r.a+")"}}
A.bQ.prototype={
i(a){var s=this.a
return s.length===0?"Error":"Error: "+s}}
A.ct.prototype={
i(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.aw.prototype={}
A.b0.prototype={
i(a){var s,r=this.b
if(r!=null)return r
r=this.a
s=r!==null&&typeof r==="object"?r.stack:null
return this.b=s==null?"":s},
$iA:1}
A.O.prototype={
i(a){var s=this.constructor,r=s==null?null:s.name
return"Closure '"+A.f5(r==null?"unknown":r)+"'"},
$iV:1,
gbv(){return this},
$C:"$1",
$R:1,
$D:null}
A.bf.prototype={$C:"$0",$R:0}
A.bg.prototype={$C:"$2",$R:2}
A.bO.prototype={}
A.bM.prototype={
i(a){var s=this.$static_name
if(s==null)return"Closure of unknown static method"
return"Closure '"+A.f5(s)+"'"}}
A.a7.prototype={
B(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.a7))return!1
return this.$_target===b.$_target&&this.a===b.a},
gm(a){return(A.ds(this.a)^A.aL(this.$_target))>>>0},
i(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.bK(this.a)+"'")}}
A.bW.prototype={
i(a){return"Reading static variable '"+this.a+"' during its initialization"}}
A.bL.prototype={
i(a){return"RuntimeError: "+this.a}}
A.W.prototype={
gk(a){return this.a},
gF(){return new A.aF(this,A.x(this).h("aF<1>"))},
A(a){var s=this.b
if(s==null)return!1
return s[a]!=null},
j(a,b){var s,r,q,p,o=null
if(typeof b=="string"){s=this.b
if(s==null)return o
r=s[b]
q=r==null?o:r.b
return q}else if(typeof b=="number"&&(b&0x3fffffff)===b){p=this.c
if(p==null)return o
r=p[b]
q=r==null?o:r.b
return q}else return this.bi(b)},
bi(a){var s,r,q=this.d
if(q==null)return null
s=q[this.aH(a)]
r=this.aI(s,a)
if(r<0)return null
return s[r].b},
v(a,b,c){var s,r,q,p,o,n,m=this
if(typeof b=="string"){s=m.b
m.al(s==null?m.b=m.a6():s,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){r=m.c
m.al(r==null?m.c=m.a6():r,b,c)}else{q=m.d
if(q==null)q=m.d=m.a6()
p=m.aH(b)
o=q[p]
if(o==null)q[p]=[m.a7(b,c)]
else{n=m.aI(o,b)
if(n>=0)o[n].b=c
else o.push(m.a7(b,c))}}},
S(a,b){var s=this,r=s.e,q=s.r
for(;r!=null;){b.$2(r.a,r.b)
if(q!==s.r)throw A.b(A.au(s))
r=r.c}},
al(a,b,c){var s=a[b]
if(s==null)a[b]=this.a7(b,c)
else s.b=c},
a7(a,b){var s=this,r=new A.cq(a,b)
if(s.e==null)s.e=s.f=r
else s.f=s.f.c=r;++s.a
s.r=s.r+1&1073741823
return r},
aH(a){return J.dx(a)&1073741823},
aI(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.ba(a[r].a,b))return r
return-1},
i(a){return A.eg(this)},
a6(){var s=Object.create(null)
s["<non-identifier-key>"]=s
delete s["<non-identifier-key>"]
return s}}
A.cq.prototype={}
A.aF.prototype={
gk(a){return this.a.a},
gq(a){var s=this.a,r=new A.bv(s,s.r,this.$ti.h("bv<1>"))
r.c=s.e
return r},
aD(a,b){return this.a.A(b)}}
A.bv.prototype={
gp(){return this.d},
n(){var s,r=this,q=r.a
if(r.b!==q.r)throw A.b(A.au(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=s.a
r.c=s.c
return!0}}}
A.di.prototype={
$1(a){return this.a(a)},
$S:11}
A.dj.prototype={
$2(a,b){return this.a(a,b)},
$S:12}
A.dk.prototype={
$1(a){return this.a(a)},
$S:13}
A.by.prototype={
gl(a){return B.A},
$ih:1,
$idB:1}
A.aI.prototype={}
A.bz.prototype={
gl(a){return B.B},
$ih:1,
$idC:1}
A.ac.prototype={
gk(a){return a.length},
$iv:1}
A.aG.prototype={
j(a,b){A.a0(b,a,a.length)
return a[b]},
$ie:1,
$id:1,
$ij:1}
A.aH.prototype={$ie:1,$id:1,$ij:1}
A.bA.prototype={
gl(a){return B.C},
$ih:1,
$icg:1}
A.bB.prototype={
gl(a){return B.D},
$ih:1,
$ich:1}
A.bC.prototype={
gl(a){return B.E},
j(a,b){A.a0(b,a,a.length)
return a[b]},
$ih:1,
$icj:1}
A.bD.prototype={
gl(a){return B.F},
j(a,b){A.a0(b,a,a.length)
return a[b]},
$ih:1,
$ick:1}
A.bE.prototype={
gl(a){return B.G},
j(a,b){A.a0(b,a,a.length)
return a[b]},
$ih:1,
$icl:1}
A.bF.prototype={
gl(a){return B.I},
j(a,b){A.a0(b,a,a.length)
return a[b]},
$ih:1,
$icz:1}
A.bG.prototype={
gl(a){return B.J},
j(a,b){A.a0(b,a,a.length)
return a[b]},
$ih:1,
$icA:1}
A.aJ.prototype={
gl(a){return B.K},
gk(a){return a.length},
j(a,b){A.a0(b,a,a.length)
return a[b]},
$ih:1,
$icB:1}
A.bH.prototype={
gl(a){return B.L},
gk(a){return a.length},
j(a,b){A.a0(b,a,a.length)
return a[b]},
$ih:1,
$icC:1}
A.aX.prototype={}
A.aY.prototype={}
A.aZ.prototype={}
A.b_.prototype={}
A.w.prototype={
h(a){return A.d6(v.typeUniverse,this,a)},
t(a){return A.he(v.typeUniverse,this,a)}}
A.c_.prototype={}
A.d5.prototype={
i(a){return A.u(this.a,null)}}
A.bZ.prototype={
i(a){return this.a}}
A.b1.prototype={$iI:1}
A.cE.prototype={
$1(a){var s=this.a,r=s.a
s.a=null
r.$0()},
$S:6}
A.cD.prototype={
$1(a){var s,r
this.a.a=a
s=this.b
r=this.c
s.firstChild?s.removeChild(r):s.appendChild(r)},
$S:14}
A.cF.prototype={
$0(){this.a.$0()},
$S:7}
A.cG.prototype={
$0(){this.a.$0()},
$S:7}
A.d3.prototype={
aX(a,b){if(self.setTimeout!=null)self.setTimeout(A.b7(new A.d4(this,b),0),a)
else throw A.b(A.dJ("`setTimeout()` not found."))}}
A.d4.prototype={
$0(){this.b.$0()},
$S:0}
A.bS.prototype={
E(a){var s,r=this
if(a==null)a=r.$ti.c.a(a)
if(!r.b)r.a.K(a)
else{s=r.a
if(r.$ti.h("F<1>").b(a))s.an(a)
else s.a1(a)}},
P(a,b){var s=this.a
if(this.b)s.C(a,b)
else s.L(a,b)}}
A.d9.prototype={
$1(a){return this.a.$2(0,a)},
$S:1}
A.da.prototype={
$2(a,b){this.a.$2(1,new A.aw(a,b))},
$S:15}
A.dd.prototype={
$2(a,b){this.a(a,b)},
$S:16}
A.be.prototype={
i(a){return A.p(this.a)},
$ik:1,
gJ(){return this.b}}
A.ae.prototype={}
A.af.prototype={
a8(){},
a9(){}}
A.bU.prototype={
ga5(){return this.c<4},
b9(a){var s=a.CW,r=a.ch
if(s==null)this.d=r
else s.ch=r
if(r==null)this.e=s
else r.CW=s
a.CW=a
a.ch=a},
bd(a,b,c,d){var s,r,q,p,o,n,m,l,k=this
if((k.c&4)!==0){s=new A.aU($.f,A.x(k).h("aU<1>"))
A.e0(s.gb6())
if(c!=null)s.c=c
return s}s=$.f
r=d?1:0
q=b!=null?32:0
p=A.eq(s,a)
o=A.er(s,b)
n=c==null?A.hW():c
m=new A.af(k,p,o,n,s,r|q,A.x(k).h("af<1>"))
m.CW=m
m.ch=m
m.ay=k.c&1
l=k.e
k.e=m
m.ch=null
m.CW=l
if(l==null)k.d=m
else l.ch=m
if(k.d===m)A.eT(k.a)
return m},
b8(a){var s,r=this
A.x(r).h("af<1>").a(a)
if(a.ch===a)return null
s=a.ay
if((s&2)!==0)a.ay=s|4
else{r.b9(a)
if((r.c&2)===0&&r.d==null)r.aZ()}return null},
Z(){if((this.c&4)!==0)return new A.Z("Cannot add new events after calling close")
return new A.Z("Cannot add new events while doing an addStream")},
aA(a,b){if(!this.ga5())throw A.b(this.Z())
this.ab(b)},
aB(a,b){A.aq(a,"error",t.K)
if(!this.ga5())throw A.b(this.Z())
if(b==null)b=A.dA(a)
this.ad(a,b)},
bf(a){return this.aB(a,null)},
D(){var s,r,q=this
if((q.c&4)!==0){s=q.r
s.toString
return s}if(!q.ga5())throw A.b(q.Z())
q.c|=4
r=q.r
if(r==null)r=q.r=new A.i($.f,t.D)
q.ac()
return r},
aZ(){if((this.c&4)!==0){var s=this.r
if((s.a&30)===0)s.K(null)}A.eT(this.b)}}
A.aQ.prototype={
ab(a){var s,r
for(s=this.d,r=this.$ti.h("bX<1>");s!=null;s=s.ch)s.a0(new A.bX(a,r))},
ad(a,b){var s
for(s=this.d;s!=null;s=s.ch)s.a0(new A.cK(a,b))},
ac(){var s=this.d
if(s!=null)for(;s!=null;s=s.ch)s.a0(B.t)
else this.r.K(null)}}
A.ci.prototype={
$0(){this.c.a(null)
this.b.aq(null)},
$S:0}
A.bV.prototype={
P(a,b){var s
A.aq(a,"error",t.K)
s=this.a
if((s.a&30)!==0)throw A.b(A.dH("Future already completed"))
if(b==null)b=A.dA(a)
s.L(a,b)},
aC(a){return this.P(a,null)}}
A.C.prototype={
E(a){var s=this.a
if((s.a&30)!==0)throw A.b(A.dH("Future already completed"))
s.K(a)},
bg(){return this.E(null)}}
A.ag.prototype={
bk(a){if((this.c&15)!==6)return!0
return this.b.b.ai(this.d,a.a)},
bh(a){var s,r=this.e,q=null,p=a.a,o=this.b.b
if(t.C.b(r))q=o.bp(r,p,a.b)
else q=o.ai(r,p)
try{p=q
return p}catch(s){if(t.w.b(A.D(s))){if((this.c&1)!==0)throw A.b(A.N("The error handler of Future.then must return a value of the returned future's type","onError"))
throw A.b(A.N("The error handler of Future.catchError must return a value of the future's type","onError"))}else throw s}}}
A.i.prototype={
aw(a){this.a=this.a&1|4
this.c=a},
Y(a,b,c){var s,r,q=$.f
if(q===B.a){if(b!=null&&!t.C.b(b)&&!t.v.b(b))throw A.b(A.dz(b,"onError",u.c))}else if(b!=null)b=A.hK(b,q)
s=new A.i(q,c.h("i<0>"))
r=b==null?1:3
this.a_(new A.ag(s,r,a,b,this.$ti.h("@<1>").t(c).h("ag<1,2>")))
return s},
bu(a,b){return this.Y(a,null,b)},
az(a,b,c){var s=new A.i($.f,c.h("i<0>"))
this.a_(new A.ag(s,19,a,b,this.$ti.h("@<1>").t(c).h("ag<1,2>")))
return s},
ba(a){this.a=this.a&1|16
this.c=a},
M(a){this.a=a.a&30|this.a&1
this.c=a.c},
a_(a){var s=this,r=s.a
if(r<=3){a.a=s.c
s.c=a}else{if((r&4)!==0){r=s.c
if((r.a&24)===0){r.a_(a)
return}s.M(r)}A.am(null,null,s.b,new A.cN(s,a))}},
aa(a){var s,r,q,p,o,n=this,m={}
m.a=a
if(a==null)return
s=n.a
if(s<=3){r=n.c
n.c=a
if(r!=null){q=a.a
for(p=a;q!=null;p=q,q=o)o=q.a
p.a=r}}else{if((s&4)!==0){s=n.c
if((s.a&24)===0){s.aa(a)
return}n.M(s)}m.a=n.O(a)
A.am(null,null,n.b,new A.cU(m,n))}},
N(){var s=this.c
this.c=null
return this.O(s)},
O(a){var s,r,q
for(s=a,r=null;s!=null;r=s,s=q){q=s.a
s.a=r}return r},
b_(a){var s,r,q,p=this
p.a^=2
try{a.Y(new A.cR(p),new A.cS(p),t.P)}catch(q){s=A.D(q)
r=A.y(q)
A.e0(new A.cT(p,s,r))}},
aq(a){var s=this,r=s.N()
s.a=8
s.c=a
A.ah(s,r)},
a1(a){var s=this,r=s.N()
s.a=8
s.c=a
A.ah(s,r)},
C(a,b){var s=this.N()
this.ba(A.ce(a,b))
A.ah(this,s)},
K(a){if(this.$ti.h("F<1>").b(a)){this.an(a)
return}this.aY(a)},
aY(a){this.a^=2
A.am(null,null,this.b,new A.cP(this,a))},
an(a){if(this.$ti.b(a)){A.fX(a,this)
return}this.b_(a)},
L(a,b){this.a^=2
A.am(null,null,this.b,new A.cO(this,a,b))},
$iF:1}
A.cN.prototype={
$0(){A.ah(this.a,this.b)},
$S:0}
A.cU.prototype={
$0(){A.ah(this.b,this.a.a)},
$S:0}
A.cR.prototype={
$1(a){var s,r,q,p=this.a
p.a^=2
try{p.a1(p.$ti.c.a(a))}catch(q){s=A.D(q)
r=A.y(q)
p.C(s,r)}},
$S:6}
A.cS.prototype={
$2(a,b){this.a.C(a,b)},
$S:17}
A.cT.prototype={
$0(){this.a.C(this.b,this.c)},
$S:0}
A.cQ.prototype={
$0(){A.et(this.a.a,this.b)},
$S:0}
A.cP.prototype={
$0(){this.a.a1(this.b)},
$S:0}
A.cO.prototype={
$0(){this.a.C(this.b,this.c)},
$S:0}
A.cX.prototype={
$0(){var s,r,q,p,o,n,m=this,l=null
try{q=m.a.a
l=q.b.b.bn(q.d)}catch(p){s=A.D(p)
r=A.y(p)
q=m.c&&m.b.a.c.a===s
o=m.a
if(q)o.c=m.b.a.c
else o.c=A.ce(s,r)
o.b=!0
return}if(l instanceof A.i&&(l.a&24)!==0){if((l.a&16)!==0){q=m.a
q.c=l.c
q.b=!0}return}if(l instanceof A.i){n=m.b.a
q=m.a
q.c=l.bu(new A.cY(n),t.z)
q.b=!1}},
$S:0}
A.cY.prototype={
$1(a){return this.a},
$S:18}
A.cW.prototype={
$0(){var s,r,q,p,o
try{q=this.a
p=q.a
q.c=p.b.b.ai(p.d,this.b)}catch(o){s=A.D(o)
r=A.y(o)
q=this.a
q.c=A.ce(s,r)
q.b=!0}},
$S:0}
A.cV.prototype={
$0(){var s,r,q,p,o,n,m=this
try{s=m.a.a.c
p=m.b
if(p.a.bk(s)&&p.a.e!=null){p.c=p.a.bh(s)
p.b=!1}}catch(o){r=A.D(o)
q=A.y(o)
p=m.a.a.c
n=m.b
if(p.a===r)n.c=p
else n.c=A.ce(r,q)
n.b=!0}},
$S:0}
A.bT.prototype={}
A.B.prototype={
gk(a){var s={},r=new A.i($.f,t.a)
s.a=0
this.G(new A.cv(s,this),!0,new A.cw(s,r),r.gb0())
return r}}
A.cv.prototype={
$1(a){++this.a.a},
$S(){return A.x(this.b).h("~(B.T)")}}
A.cw.prototype={
$0(){this.b.aq(this.a.a)},
$S:0}
A.aS.prototype={
gm(a){return(A.aL(this.a)^892482866)>>>0},
B(a,b){if(b==null)return!1
if(this===b)return!0
return b instanceof A.ae&&b.a===this.a}}
A.aT.prototype={
av(){return this.w.b8(this)},
a8(){},
a9(){}}
A.aR.prototype={
U(a){this.a=A.eq(this.d,a)},
V(a){var s=this,r=s.e
if(a==null)s.e=r&4294967263
else s.e=r|32
s.b=A.er(s.d,a)},
am(){var s,r=this,q=r.e|=8
if((q&128)!==0){s=r.r
if(s.a===1)s.a=3}if((q&64)===0)r.r=null
r.f=r.av()},
a8(){},
a9(){},
av(){return null},
a0(a){var s,r,q=this,p=q.r
if(p==null)p=q.r=new A.c2(A.x(q).h("c2<1>"))
s=p.c
if(s==null)p.b=p.c=a
else{s.sH(a)
p.c=a}r=q.e
if((r&128)===0){r|=128
q.e=r
if(r<256)p.aj(q)}},
ab(a){var s=this,r=s.e
s.e=r|64
s.d.X(s.a,a)
s.e&=4294967231
s.ao((r&4)!==0)},
ad(a,b){var s=this,r=s.e,q=new A.cI(s,a,b)
if((r&1)!==0){s.e=r|16
s.am()
q.$0()}else{q.$0()
s.ao((r&4)!==0)}},
ac(){this.am()
this.e|=16
new A.cH(this).$0()},
ao(a){var s,r,q=this,p=q.e
if((p&128)!==0&&q.r.c==null){p=q.e=p&4294967167
s=!1
if((p&4)!==0)if(p<256){s=q.r
s=s==null?null:s.c==null
s=s!==!1}if(s){p&=4294967291
q.e=p}}for(;!0;a=r){if((p&8)!==0){q.r=null
return}r=(p&4)!==0
if(a===r)break
q.e=p^64
if(r)q.a8()
else q.a9()
p=q.e&=4294967231}if((p&128)!==0&&p<256)q.r.aj(q)}}
A.cI.prototype={
$0(){var s,r,q=this.a,p=q.e
if((p&8)!==0&&(p&16)===0)return
q.e=p|64
s=q.b
p=this.b
r=q.d
if(t.k.b(s))r.aP(s,p,this.c)
else r.X(s,p)
q.e&=4294967231},
$S:0}
A.cH.prototype={
$0(){var s=this.a,r=s.e
if((r&16)===0)return
s.e=r|74
s.d.ah(s.c)
s.e&=4294967231},
$S:0}
A.aj.prototype={
G(a,b,c,d){return this.a.bd(a,d,c,b===!0)},
aL(a){return this.G(a,null,null,null)},
aM(a,b,c){return this.G(a,b,c,null)}}
A.bY.prototype={
gH(){return this.a},
sH(a){return this.a=a}}
A.bX.prototype={
ag(a){a.ab(this.b)}}
A.cK.prototype={
ag(a){a.ad(this.b,this.c)}}
A.cJ.prototype={
ag(a){a.ac()},
gH(){return null},
sH(a){throw A.b(A.dH("No events after a done."))}}
A.c2.prototype={
aj(a){var s=this,r=s.a
if(r===1)return
if(r>=1){s.a=1
return}A.e0(new A.d0(s,a))
s.a=1}}
A.d0.prototype={
$0(){var s,r,q=this.a,p=q.a
q.a=0
if(p===3)return
s=q.b
r=s.gH()
q.b=r
if(r==null)q.c=null
s.ag(this.b)},
$S:0}
A.aU.prototype={
U(a){},
V(a){},
b7(){var s,r=this,q=r.a-1
if(q===0){r.a=-1
s=r.c
if(s!=null){r.c=null
r.b.ah(s)}}else r.a=q}}
A.c3.prototype={}
A.d8.prototype={}
A.dc.prototype={
$0(){A.ft(this.a,this.b)},
$S:0}
A.d1.prototype={
ah(a){var s,r,q
try{if(B.a===$.f){a.$0()
return}A.eP(null,null,this,a)}catch(q){s=A.D(q)
r=A.y(q)
A.al(s,r)}},
bt(a,b){var s,r,q
try{if(B.a===$.f){a.$1(b)
return}A.eR(null,null,this,a,b)}catch(q){s=A.D(q)
r=A.y(q)
A.al(s,r)}},
X(a,b){return this.bt(a,b,t.z)},
br(a,b,c){var s,r,q
try{if(B.a===$.f){a.$2(b,c)
return}A.eQ(null,null,this,a,b,c)}catch(q){s=A.D(q)
r=A.y(q)
A.al(s,r)}},
aP(a,b,c){var s=t.z
return this.br(a,b,c,s,s)},
ae(a){return new A.d2(this,a)},
bo(a){if($.f===B.a)return a.$0()
return A.eP(null,null,this,a)},
bn(a){return this.bo(a,t.z)},
bs(a,b){if($.f===B.a)return a.$1(b)
return A.eR(null,null,this,a,b)},
ai(a,b){var s=t.z
return this.bs(a,b,s,s)},
bq(a,b,c){if($.f===B.a)return a.$2(b,c)
return A.eQ(null,null,this,a,b,c)},
bp(a,b,c){var s=t.z
return this.bq(a,b,c,s,s,s)},
bm(a){return a},
W(a){var s=t.z
return this.bm(a,s,s,s)}}
A.d2.prototype={
$0(){return this.a.ah(this.b)},
$S:0}
A.aV.prototype={
gk(a){return this.a},
gF(){return new A.aW(this,this.$ti.h("aW<1>"))},
A(a){var s,r
if(typeof a=="string"&&a!=="__proto__"){s=this.b
return s==null?!1:s[a]!=null}else if(typeof a=="number"&&(a&1073741823)===a){r=this.c
return r==null?!1:r[a]!=null}else return this.b1(a)},
b1(a){var s=this.d
if(s==null)return!1
return this.a4(this.au(s,a),a)>=0},
j(a,b){var s,r,q
if(typeof b=="string"&&b!=="__proto__"){s=this.b
r=s==null?null:A.eu(s,b)
return r}else if(typeof b=="number"&&(b&1073741823)===b){q=this.c
r=q==null?null:A.eu(q,b)
return r}else return this.b3(b)},
b3(a){var s,r,q=this.d
if(q==null)return null
s=this.au(q,a)
r=this.a4(s,a)
return r<0?null:s[r+1]},
v(a,b,c){var s,r,q,p,o,n,m=this
if(typeof b=="string"&&b!=="__proto__"){s=m.b
m.ap(s==null?m.b=A.dK():s,b,c)}else if(typeof b=="number"&&(b&1073741823)===b){r=m.c
m.ap(r==null?m.c=A.dK():r,b,c)}else{q=m.d
if(q==null)q=m.d=A.dK()
p=A.ds(b)&1073741823
o=q[p]
if(o==null){A.dL(q,p,[b,c]);++m.a
m.e=null}else{n=m.a4(o,b)
if(n>=0)o[n+1]=c
else{o.push(b,c);++m.a
m.e=null}}}},
S(a,b){var s,r,q,p,o,n=this,m=n.ar()
for(s=m.length,r=n.$ti.y[1],q=0;q<s;++q){p=m[q]
o=n.j(0,p)
b.$2(p,o==null?r.a(o):o)
if(m!==n.e)throw A.b(A.au(n))}},
ar(){var s,r,q,p,o,n,m,l,k,j,i=this,h=i.e
if(h!=null)return h
h=A.fD(i.a,null,!1,t.z)
s=i.b
r=0
if(s!=null){q=Object.getOwnPropertyNames(s)
p=q.length
for(o=0;o<p;++o){h[r]=q[o];++r}}n=i.c
if(n!=null){q=Object.getOwnPropertyNames(n)
p=q.length
for(o=0;o<p;++o){h[r]=+q[o];++r}}m=i.d
if(m!=null){q=Object.getOwnPropertyNames(m)
p=q.length
for(o=0;o<p;++o){l=m[q[o]]
k=l.length
for(j=0;j<k;j+=2){h[r]=l[j];++r}}}return i.e=h},
ap(a,b,c){if(a[b]==null){++this.a
this.e=null}A.dL(a,b,c)},
au(a,b){return a[A.ds(b)&1073741823]}}
A.ai.prototype={
a4(a,b){var s,r,q
if(a==null)return-1
s=a.length
for(r=0;r<s;r+=2){q=a[r]
if(q==null?b==null:q===b)return r}return-1}}
A.aW.prototype={
gk(a){return this.a.a},
gq(a){var s=this.a
return new A.c0(s,s.ar(),this.$ti.h("c0<1>"))},
aD(a,b){return this.a.A(b)}}
A.c0.prototype={
gp(){var s=this.d
return s==null?this.$ti.c.a(s):s},
n(){var s=this,r=s.b,q=s.c,p=s.a
if(r!==p.e)throw A.b(A.au(p))
else if(q>=r.length){s.d=null
return!1}else{s.d=r[q]
s.c=q+1
return!0}}}
A.m.prototype={
gq(a){return new A.a9(a,this.gk(a),A.ar(a).h("a9<m.E>"))},
R(a,b){return this.j(a,b)},
gaF(a){if(this.gk(a)===0)throw A.b(A.co())
return this.j(a,0)},
gaK(a){if(this.gk(a)===0)throw A.b(A.co())
return this.j(a,this.gk(a)-1)},
T(a,b,c){return new A.H(a,b,A.ar(a).h("@<m.E>").t(c).h("H<1,2>"))},
i(a){return A.ed(a,"[","]")}}
A.X.prototype={
S(a,b){var s,r,q,p
for(s=this.gF(),s=s.gq(s),r=A.x(this).y[1];s.n();){q=s.gp()
p=this.j(0,q)
b.$2(q,p==null?r.a(p):p)}},
bj(a,b,c,d){var s,r,q,p,o,n=A.dF(c,d)
for(s=this.gF(),s=s.gq(s),r=A.x(this).y[1];s.n();){q=s.gp()
p=this.j(0,q)
o=b.$2(q,p==null?r.a(p):p)
n.v(0,o.a,o.b)}return n},
A(a){return this.gF().aD(0,a)},
gk(a){var s=this.gF()
return s.gk(s)},
i(a){return A.eg(this)},
$iaa:1}
A.cr.prototype={
$2(a,b){var s,r=this.a
if(!r.a)this.b.a+=", "
r.a=!1
r=this.b
s=A.p(a)
s=r.a+=s
r.a=s+": "
s=A.p(b)
r.a+=s},
$S:19}
A.bi.prototype={
B(a,b){var s
if(b==null)return!1
s=!1
if(b instanceof A.bi)if(this.a===b.a)s=this.b===b.b
return s},
gm(a){return A.fF(this.a,this.b)},
i(a){var s=this,r=A.fr(A.fO(s)),q=A.bj(A.fM(s)),p=A.bj(A.fI(s)),o=A.bj(A.fJ(s)),n=A.bj(A.fL(s)),m=A.bj(A.fN(s)),l=A.ea(A.fK(s)),k=s.b,j=k===0?"":A.ea(k)
return r+"-"+q+"-"+p+" "+o+":"+n+":"+m+"."+l+j+"Z"}}
A.bk.prototype={
B(a,b){if(b==null)return!1
return b instanceof A.bk},
gm(a){return B.b.gm(0)},
i(a){return"0:00:00."+B.i.bl(B.b.i(0),6,"0")}}
A.cL.prototype={
i(a){return this.b2()}}
A.k.prototype={
gJ(){return A.fH(this)}}
A.bc.prototype={
i(a){var s=this.a
if(s!=null)return"Assertion failed: "+A.cf(s)
return"Assertion failed"}}
A.I.prototype={}
A.E.prototype={
ga3(){return"Invalid argument"+(!this.a?"(s)":"")},
ga2(){return""},
i(a){var s=this,r=s.c,q=r==null?"":" ("+r+")",p=s.d,o=p==null?"":": "+p,n=s.ga3()+q+o
if(!s.a)return n
return n+s.ga2()+": "+A.cf(s.gaf())},
gaf(){return this.b}}
A.aM.prototype={
gaf(){return this.b},
ga3(){return"RangeError"},
ga2(){var s,r=this.e,q=this.f
if(r==null)s=q!=null?": Not less than or equal to "+A.p(q):""
else if(q==null)s=": Not greater than or equal to "+A.p(r)
else if(q>r)s=": Not in inclusive range "+A.p(r)+".."+A.p(q)
else s=q<r?": Valid value range is empty":": Only valid value is "+A.p(r)
return s}}
A.bl.prototype={
gaf(){return this.b},
ga3(){return"RangeError"},
ga2(){if(this.b<0)return": index must not be negative"
var s=this.f
if(s===0)return": no indices are valid"
return": index should be less than "+s},
gk(a){return this.f}}
A.bR.prototype={
i(a){return"Unsupported operation: "+this.a}}
A.bP.prototype={
i(a){var s=this.a
return s!=null?"UnimplementedError: "+s:"UnimplementedError"}}
A.Z.prototype={
i(a){return"Bad state: "+this.a}}
A.bh.prototype={
i(a){var s=this.a
if(s==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.cf(s)+"."}}
A.bI.prototype={
i(a){return"Out of Memory"},
gJ(){return null},
$ik:1}
A.aN.prototype={
i(a){return"Stack Overflow"},
gJ(){return null},
$ik:1}
A.cM.prototype={
i(a){return"Exception: "+this.a}}
A.d.prototype={
T(a,b,c){return A.fE(this,b,A.x(this).h("d.E"),c)},
gk(a){var s,r=this.gq(this)
for(s=0;r.n();)++s
return s},
i(a){return A.fy(this,"(",")")}}
A.ab.prototype={
i(a){return"MapEntry("+A.p(this.a)+": "+A.p(this.b)+")"}}
A.q.prototype={
gm(a){return A.c.prototype.gm.call(this,0)},
i(a){return"null"}}
A.c.prototype={$ic:1,
B(a,b){return this===b},
gm(a){return A.aL(this)},
i(a){return"Instance of '"+A.bK(this)+"'"},
gl(a){return A.ia(this)},
toString(){return this.i(this)}}
A.c4.prototype={
i(a){return this.a},
$iA:1}
A.bN.prototype={
gk(a){return this.a.length},
i(a){var s=this.a
return s.charCodeAt(0)==0?s:s}}
A.dp.prototype={
$1(a){var s,r,q,p
if(A.eO(a))return a
s=this.a
if(s.A(a))return s.j(0,a)
if(t.d.b(a)){r={}
s.v(0,a,r)
for(s=a.gF(),s=s.gq(s);s.n();){q=s.gp()
r[q]=this.$1(a.j(0,q))}return r}else if(t.x.b(a)){p=[]
s.v(0,a,p)
B.x.be(p,J.dy(a,this,t.z))
return p}else return a},
$S:2}
A.dt.prototype={
$1(a){return this.a.E(a)},
$S:1}
A.du.prototype={
$1(a){if(a==null)return this.a.aC(new A.cs(a===undefined))
return this.a.aC(a)},
$S:1}
A.df.prototype={
$1(a){var s,r,q,p,o,n,m,l,k,j,i,h
if(A.eN(a))return a
s=this.a
a.toString
if(s.A(a))return s.j(0,a)
if(a instanceof Date){r=a.getTime()
if(r<-864e13||r>864e13)A.a4(A.ei(r,-864e13,864e13,"millisecondsSinceEpoch",null))
A.aq(!0,"isUtc",t.y)
return new A.bi(r,0,!0)}if(a instanceof RegExp)throw A.b(A.N("structured clone of RegExp",null))
if(typeof Promise!="undefined"&&a instanceof Promise)return A.ip(a,t.X)
q=Object.getPrototypeOf(a)
if(q===Object.prototype||q===null){p=t.X
o=A.dF(p,p)
s.v(0,a,o)
n=Object.keys(a)
m=[]
for(s=J.a3(n),p=s.gq(n);p.n();)m.push(A.eY(p.gp()))
for(l=0;l<s.gk(n);++l){k=s.j(n,l)
j=m[l]
if(k!=null)o.v(0,j,this.$1(a[k]))}return o}if(a instanceof Array){i=a
o=[]
s.v(0,a,o)
h=a.length
for(s=J.a3(i),l=0;l<h;++l)o.push(this.$1(s.j(i,l)))
return o}return a},
$S:2}
A.cs.prototype={
i(a){return"Promise was rejected with a value of `"+(this.a?"undefined":"null")+"`."}}
A.cn.prototype={
$1(a){return this.a.a(a)},
$S(){return this.a.h("0(@)")}}
A.ay.prototype={
aV(a,b,c,d,e){this.a.onmessage=A.eJ(new A.cm(this))},
gaE(){return this.a},
gaN(){return A.a4(A.aO(null))},
aG(){return A.a4(A.aO(null))},
I(a){return A.a4(A.aO(null))},
ak(a){return A.a4(A.aO(null))},
D(){var s=0,r=A.cb(t.H),q=this
var $async$D=A.cd(function(a,b){if(a===1)return A.c8(b,r)
while(true)switch(s){case 0:q.a.terminate()
s=2
return A.c7(q.b.D(),$async$D)
case 2:return A.c9(null,r)}})
return A.ca($async$D,r)},
$iec:1}
A.cm.prototype={
$1(a){var s,r,q=this,p="type",o=A.dT(a.data)
o.toString
s=t.f
s.a(o)
if(J.ba(o.j(0,p),"data")){s=q.a
s.b.aA(0,s.d.$1(o.j(0,"value")))
return}if(B.w.aJ(o)){o=q.a.f
if((o.a.a&30)===0)o.bg()
return}if(B.v.aJ(o)){o=q.a
o.c.$0()
o.D()
return}if(o.A(p)&&J.ba(o.j(0,p),"$IsolateException")){r=s.a(o.j(0,"value"))
o=r.j(0,"error")
if(o==null)o=t.K.a(o)
A.hi(r.j(0,"stack"))
q.a.b.aB(J.a6(o),B.e)
return}q.a.b.bf("Instance of '"+A.bK(new A.bn("Unhandled "+o.i(0)+" from the Isolate",B.e))+"'")},
$S:8}
A.bn.prototype={}
A.bp.prototype={
b2(){return"IsolateState."+this.b},
aJ(a){return a.A("type")&&J.ba(a.j(0,"type"),"$IsolateState")&&J.ba(a.j(0,"value"),this.b)}}
A.de.prototype={
$2(a,b){this.a.v(0,a,A.dS(b))},
$S:20}
A.dq.prototype={
$2(a,b){return new A.ab(A.b9(a),A.b9(b),t.t)},
$S:21}
A.dv.prototype={
$1(a){var s=J.a3(a)
return A.dW([this.a.j(0,s.j(a,0)),s.j(a,1)])},
$S:22}
A.az.prototype={
I(a){return this.a.a.I(a)}}
A.bo.prototype={}
A.c1.prototype={
aW(a,b,c,d){this.a.onmessage=A.eJ(new A.cZ(this,d))},
gaN(){var s=this.c,r=A.x(s).h("ae<1>")
return new A.as(new A.ae(s,r),r.h("@<B.T>").t(this.$ti.y[1]).h("as<1,2>"))},
I(a){this.a.postMessage(A.b9(A.bw(["type","data","value",a],t.N,t.X)))},
ak(a){var s=t.N
this.a.postMessage(A.b9(A.bw(["type","$IsolateException","value",A.bw(["error",J.a6(a.a),"stack",a.b.i(0)],s,s)],s,t.z)))},
aG(){var s=t.N
this.a.postMessage(A.b9(A.bw(["type","$IsolateState","value","initialized"],s,s)))}}
A.cZ.prototype={
$1(a){this.a.c.aA(0,this.b.a(A.dT(a.data)))},
$S:8}
A.dn.prototype={
$1(a){var s,r,q,p=this.d,o=new A.C(new A.i($.f,p.h("i<0>")),p.h("C<0>"))
p=this.a
o.a.Y(p.gaT(),new A.dm(p),t.H)
try{o.E(this.b.$1(a))}catch(q){s=A.D(q)
r=A.y(q)
o.P(s,r)}},
$S(){return this.c.h("~(0)")}}
A.dm.prototype={
$2(a,b){return this.a.a.a.ak(new A.bn(a,b))},
$S:3};(function aliases(){var s=J.Q.prototype
s.aU=s.i})();(function installTearOffs(){var s=hunkHelpers._instance_1u,r=hunkHelpers._static_1,q=hunkHelpers._static_0,p=hunkHelpers._static_2,o=hunkHelpers._instance_2u,n=hunkHelpers._instance_0u
s(A.at.prototype,"gb4","b5",5)
r(A,"hS","fU",4)
r(A,"hT","fV",4)
r(A,"hU","fW",4)
q(A,"eW","hM",0)
r(A,"hV","hG",1)
p(A,"hX","hI",3)
q(A,"hW","hH",0)
o(A.i.prototype,"gb0","C",3)
n(A.aU.prototype,"gb6","b7",0)
r(A,"iv","dS",2)
r(A,"iw","b9",2)
s(A.az.prototype,"gaT","I",5)
r(A,"i5","i_",9)
r(A,"i8","a1",10)
r(A,"i7","dh",10)
r(A,"i6","i1",9)})();(function inheritance(){var s=hunkHelpers.mixin,r=hunkHelpers.inherit,q=hunkHelpers.inheritMany
r(A.c,null)
q(A.c,[A.dD,J.bm,J.bb,A.B,A.at,A.k,A.cu,A.d,A.a9,A.bx,A.ax,A.cx,A.ct,A.aw,A.b0,A.O,A.X,A.cq,A.bv,A.w,A.c_,A.d5,A.d3,A.bS,A.be,A.aR,A.bU,A.bV,A.ag,A.i,A.bT,A.bY,A.cJ,A.c2,A.aU,A.c3,A.d8,A.c0,A.m,A.bi,A.bk,A.cL,A.bI,A.aN,A.cM,A.ab,A.q,A.c4,A.bN,A.cs,A.ay,A.bn,A.az,A.bo,A.c1])
q(J.bm,[J.bq,J.aB,J.aD,J.aC,J.aE,J.bs,J.a8])
q(J.aD,[J.Q,J.r,A.by,A.aI])
q(J.Q,[J.bJ,J.aP,J.P])
r(J.cp,J.r)
q(J.bs,[J.aA,J.br])
q(A.B,[A.as,A.aj])
q(A.k,[A.bu,A.I,A.bt,A.bQ,A.bW,A.bL,A.bZ,A.bc,A.E,A.bR,A.bP,A.Z,A.bh])
q(A.d,[A.e,A.Y])
q(A.e,[A.G,A.aF,A.aW])
r(A.av,A.Y)
r(A.H,A.G)
r(A.aK,A.I)
q(A.O,[A.bf,A.bg,A.bO,A.di,A.dk,A.cE,A.cD,A.d9,A.cR,A.cY,A.cv,A.dp,A.dt,A.du,A.df,A.cn,A.cm,A.dv,A.cZ,A.dn])
q(A.bO,[A.bM,A.a7])
q(A.X,[A.W,A.aV])
q(A.bg,[A.dj,A.da,A.dd,A.cS,A.cr,A.de,A.dq,A.dm])
q(A.aI,[A.bz,A.ac])
q(A.ac,[A.aX,A.aZ])
r(A.aY,A.aX)
r(A.aG,A.aY)
r(A.b_,A.aZ)
r(A.aH,A.b_)
q(A.aG,[A.bA,A.bB])
q(A.aH,[A.bC,A.bD,A.bE,A.bF,A.bG,A.aJ,A.bH])
r(A.b1,A.bZ)
q(A.bf,[A.cF,A.cG,A.d4,A.ci,A.cN,A.cU,A.cT,A.cQ,A.cP,A.cO,A.cX,A.cW,A.cV,A.cw,A.cI,A.cH,A.d0,A.dc,A.d2])
r(A.aS,A.aj)
r(A.ae,A.aS)
r(A.aT,A.aR)
r(A.af,A.aT)
r(A.aQ,A.bU)
r(A.C,A.bV)
q(A.bY,[A.bX,A.cK])
r(A.d1,A.d8)
r(A.ai,A.aV)
q(A.E,[A.aM,A.bl])
r(A.bp,A.cL)
s(A.aX,A.m)
s(A.aY,A.ax)
s(A.aZ,A.m)
s(A.b_,A.ax)})()
var v={typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{a:"int",l:"double",io:"num",a_:"String",hY:"bool",q:"Null",j:"List",c:"Object",aa:"Map"},mangledNames:{},types:["~()","~(@)","c?(c?)","~(c,A)","~(~())","~(c?)","q(@)","q()","q(o)","a(a)","F<a>(a)","@(@)","@(@,a_)","@(a_)","q(~())","q(@,A)","~(a,@)","q(c,A)","i<@>(@)","~(c?,c?)","~(@,@)","ab<c?,c?>(@,@)","F<@>(j<@>)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti")}
A.hd(v.typeUniverse,JSON.parse('{"bJ":"Q","aP":"Q","P":"Q","bq":{"h":[]},"aB":{"q":[],"h":[]},"aD":{"o":[]},"Q":{"o":[]},"r":{"j":["1"],"e":["1"],"o":[],"d":["1"]},"cp":{"r":["1"],"j":["1"],"e":["1"],"o":[],"d":["1"]},"bs":{"l":[]},"aA":{"l":[],"a":[],"h":[]},"br":{"l":[],"h":[]},"a8":{"a_":[],"h":[]},"as":{"B":["2"],"B.T":"2"},"bu":{"k":[]},"e":{"d":["1"]},"G":{"e":["1"],"d":["1"]},"Y":{"d":["2"],"d.E":"2"},"av":{"Y":["1","2"],"e":["2"],"d":["2"],"d.E":"2"},"H":{"G":["2"],"e":["2"],"d":["2"],"G.E":"2","d.E":"2"},"aK":{"I":[],"k":[]},"bt":{"k":[]},"bQ":{"k":[]},"b0":{"A":[]},"O":{"V":[]},"bf":{"V":[]},"bg":{"V":[]},"bO":{"V":[]},"bM":{"V":[]},"a7":{"V":[]},"bW":{"k":[]},"bL":{"k":[]},"W":{"X":["1","2"],"aa":["1","2"]},"aF":{"e":["1"],"d":["1"],"d.E":"1"},"by":{"o":[],"dB":[],"h":[]},"aI":{"o":[]},"bz":{"dC":[],"o":[],"h":[]},"ac":{"v":["1"],"o":[]},"aG":{"m":["l"],"j":["l"],"v":["l"],"e":["l"],"o":[],"d":["l"]},"aH":{"m":["a"],"j":["a"],"v":["a"],"e":["a"],"o":[],"d":["a"]},"bA":{"cg":[],"m":["l"],"j":["l"],"v":["l"],"e":["l"],"o":[],"d":["l"],"h":[],"m.E":"l"},"bB":{"ch":[],"m":["l"],"j":["l"],"v":["l"],"e":["l"],"o":[],"d":["l"],"h":[],"m.E":"l"},"bC":{"cj":[],"m":["a"],"j":["a"],"v":["a"],"e":["a"],"o":[],"d":["a"],"h":[],"m.E":"a"},"bD":{"ck":[],"m":["a"],"j":["a"],"v":["a"],"e":["a"],"o":[],"d":["a"],"h":[],"m.E":"a"},"bE":{"cl":[],"m":["a"],"j":["a"],"v":["a"],"e":["a"],"o":[],"d":["a"],"h":[],"m.E":"a"},"bF":{"cz":[],"m":["a"],"j":["a"],"v":["a"],"e":["a"],"o":[],"d":["a"],"h":[],"m.E":"a"},"bG":{"cA":[],"m":["a"],"j":["a"],"v":["a"],"e":["a"],"o":[],"d":["a"],"h":[],"m.E":"a"},"aJ":{"cB":[],"m":["a"],"j":["a"],"v":["a"],"e":["a"],"o":[],"d":["a"],"h":[],"m.E":"a"},"bH":{"cC":[],"m":["a"],"j":["a"],"v":["a"],"e":["a"],"o":[],"d":["a"],"h":[],"m.E":"a"},"bZ":{"k":[]},"b1":{"I":[],"k":[]},"i":{"F":["1"]},"be":{"k":[]},"ae":{"aj":["1"],"B":["1"],"B.T":"1"},"af":{"aR":["1"]},"aQ":{"bU":["1"]},"C":{"bV":["1"]},"aS":{"aj":["1"],"B":["1"]},"aT":{"aR":["1"]},"aj":{"B":["1"]},"aV":{"X":["1","2"],"aa":["1","2"]},"ai":{"aV":["1","2"],"X":["1","2"],"aa":["1","2"]},"aW":{"e":["1"],"d":["1"],"d.E":"1"},"X":{"aa":["1","2"]},"j":{"e":["1"],"d":["1"]},"bc":{"k":[]},"I":{"k":[]},"E":{"k":[]},"aM":{"k":[]},"bl":{"k":[]},"bR":{"k":[]},"bP":{"k":[]},"Z":{"k":[]},"bh":{"k":[]},"bI":{"k":[]},"aN":{"k":[]},"c4":{"A":[]},"ay":{"ec":["1","2"]},"cl":{"j":["a"],"e":["a"],"d":["a"]},"cC":{"j":["a"],"e":["a"],"d":["a"]},"cB":{"j":["a"],"e":["a"],"d":["a"]},"cj":{"j":["a"],"e":["a"],"d":["a"]},"cz":{"j":["a"],"e":["a"],"d":["a"]},"ck":{"j":["a"],"e":["a"],"d":["a"]},"cA":{"j":["a"],"e":["a"],"d":["a"]},"cg":{"j":["l"],"e":["l"],"d":["l"]},"ch":{"j":["l"],"e":["l"],"d":["l"]}}'))
A.hc(v.typeUniverse,JSON.parse('{"e":1,"ax":1,"ac":1,"aS":1,"aT":1,"bY":1}'))
var u={c:"Error handler must accept one Object or one Object and a StackTrace as arguments, and return a value of the returned future's type",h:"handleError callback must take either an Object (the error), or both an Object (the error) and a StackTrace."}
var t=(function rtii(){var s=A.f_
return{J:s("dB"),Y:s("dC"),V:s("e<@>"),Q:s("k"),E:s("cg"),q:s("ch"),Z:s("V"),O:s("cj"),e:s("ck"),U:s("cl"),r:s("ec<@,@>"),x:s("d<c?>"),s:s("r<a_>"),b:s("r<@>"),T:s("aB"),m:s("o"),g:s("P"),p:s("v<@>"),j:s("j<@>"),t:s("ab<c?,c?>"),f:s("aa<@,@>"),d:s("aa<c?,c?>"),P:s("q"),K:s("c"),B:s("c()"),L:s("iz"),l:s("A"),N:s("a_"),R:s("h"),w:s("I"),G:s("cz"),I:s("cA"),M:s("cB"),W:s("cC"),o:s("aP"),b3:s("C<@>"),h:s("C<~>"),c:s("i<@>"),a:s("i<a>"),D:s("i<~>"),A:s("ai<c?,c?>"),y:s("hY"),i:s("l"),z:s("@"),v:s("@(c)"),C:s("@(c,A)"),S:s("a"),F:s("0&*"),_:s("c*"),bc:s("F<q>?"),X:s("c?"),n:s("io"),H:s("~"),u:s("~(c)"),k:s("~(c,A)")}})();(function constants(){B.u=J.bm.prototype
B.x=J.r.prototype
B.b=J.aA.prototype
B.i=J.a8.prototype
B.y=J.P.prototype
B.z=J.aD.prototype
B.j=J.bJ.prototype
B.d=J.aP.prototype
B.c=new A.bk()
B.f=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.l=function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }
  var isBrowser = typeof HTMLElement == "function";
  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}
B.q=function(getTagFallback) {
  return function(hooks) {
    if (typeof navigator != "object") return hooks;
    var userAgent = navigator.userAgent;
    if (typeof userAgent != "string") return hooks;
    if (userAgent.indexOf("DumpRenderTree") >= 0) return hooks;
    if (userAgent.indexOf("Chrome") >= 0) {
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }
    hooks.getTag = getTagFallback;
  };
}
B.m=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.p=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Firefox") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};
  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }
  hooks.getTag = getTagFirefox;
}
B.o=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Trident/") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };
  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }
  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }
  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}
B.n=function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }
  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;
    return prototypeForTag(tag);
  }
  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}
B.h=function(hooks) { return hooks; }

B.r=new A.bI()
B.M=new A.cu()
B.t=new A.cJ()
B.a=new A.d1()
B.v=new A.bp("dispose")
B.w=new A.bp("initialized")
B.A=A.z("dB")
B.B=A.z("dC")
B.C=A.z("cg")
B.D=A.z("ch")
B.E=A.z("cj")
B.F=A.z("ck")
B.G=A.z("cl")
B.k=A.z("o")
B.H=A.z("c")
B.I=A.z("cz")
B.J=A.z("cA")
B.K=A.z("cB")
B.L=A.z("cC")
B.e=new A.c4("")})();(function staticFields(){$.d_=null
$.a5=A.an([],A.f_("r<c>"))
$.eh=null
$.e7=null
$.e6=null
$.f1=null
$.eV=null
$.f4=null
$.dg=null
$.dl=null
$.dV=null
$.ak=null
$.b5=null
$.b6=null
$.dQ=!1
$.f=B.a
$.im=A.bw(["countEven",A.i5(),"fibonacciRecursiveFuture",A.i8(),"fibonacciFuture",A.i7(),"fibonacci",A.i6()],t.N,t.Z)})();(function lazyInitializers(){var s=hunkHelpers.lazyFinal
s($,"iy","dw",()=>A.i9("_$dart_dartClosure"))
s($,"iB","f6",()=>A.J(A.cy({
toString:function(){return"$receiver$"}})))
s($,"iC","f7",()=>A.J(A.cy({$method$:null,
toString:function(){return"$receiver$"}})))
s($,"iD","f8",()=>A.J(A.cy(null)))
s($,"iE","f9",()=>A.J(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(r){return r.message}}()))
s($,"iH","fc",()=>A.J(A.cy(void 0)))
s($,"iI","fd",()=>A.J(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(r){return r.message}}()))
s($,"iG","fb",()=>A.J(A.ep(null)))
s($,"iF","fa",()=>A.J(function(){try{null.$method$}catch(r){return r.message}}()))
s($,"iK","ff",()=>A.J(A.ep(void 0)))
s($,"iJ","fe",()=>A.J(function(){try{(void 0).$method$}catch(r){return r.message}}()))
s($,"iL","e1",()=>A.fT())
s($,"j_","fg",()=>A.ds(B.H))})();(function nativeSupport(){!function(){var s=function(a){var m={}
m[a]=1
return Object.keys(hunkHelpers.convertToFastObject(m))[0]}
v.getIsolateTag=function(a){return s("___dart_"+a+v.isolateTag)}
var r="___dart_isolate_tags_"
var q=Object[r]||(Object[r]=Object.create(null))
var p="_ZxYxX"
for(var o=0;;o++){var n=s(p+"_"+o+"_")
if(!(n in q)){q[n]=1
v.isolateTag=n
break}}v.dispatchPropertyName=v.getIsolateTag("dispatch_record")}()
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:A.by,ArrayBufferView:A.aI,DataView:A.bz,Float32Array:A.bA,Float64Array:A.bB,Int16Array:A.bC,Int32Array:A.bD,Int8Array:A.bE,Uint16Array:A.bF,Uint32Array:A.bG,Uint8ClampedArray:A.aJ,CanvasPixelArray:A.aJ,Uint8Array:A.bH})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.ac.$nativeSuperclassTag="ArrayBufferView"
A.aX.$nativeSuperclassTag="ArrayBufferView"
A.aY.$nativeSuperclassTag="ArrayBufferView"
A.aG.$nativeSuperclassTag="ArrayBufferView"
A.aZ.$nativeSuperclassTag="ArrayBufferView"
A.b_.$nativeSuperclassTag="ArrayBufferView"
A.aH.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$0=function(){return this()}
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$1$1=function(a){return this(a)}
Function.prototype.$2$1=function(a){return this(a)}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
Function.prototype.$4=function(a,b,c,d){return this(a,b,c,d)}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var s=document.scripts
function onLoad(b){for(var q=0;q<s.length;++q){s[q].removeEventListener("load",onLoad,false)}a(b.target)}for(var r=0;r<s.length;++r){s[r].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var s=A.ik
if(typeof dartMainRunner==="function"){dartMainRunner(s,[])}else{s([])}})})()