"""
# distutils: language = C++
"""
import numpy as np

cimport numpy as np
from cpython cimport bool

cimport pele.potentials._pele as _pele
from pele.potentials._pele cimport shared_ptr

# cython has no support for integer template argument.  This is a hack to get around it
# https://groups.google.com/forum/#!topic/cython-users/xAZxdCFw6Xs
# Basically you fool cython into thinking INT2 is the type integer,
# but in the generated c++ code you use 2 instead.
# The cython code MyClass[INT2] will create c++ code MyClass<2>.
cdef extern from *:
    ctypedef int INT2 "2"    # a fake type
    ctypedef int INT3 "3"    # a fake type


# use external c++ class
cdef extern from "pele/inversepower.h" namespace "pele":
    cdef cppclass  cInversePower "pele::InversePower"[ndim]:
        cInversePower(double pow, double eps, _pele.Array[double] radii) except +
    cdef cppclass  cInversePowerPeriodic "pele::InversePowerPeriodic"[ndim]:
        cInversePowerPeriodic(double pow, double eps, _pele.Array[double] radii, _pele.Array[double] boxvec) except +

cdef class InversePower(_pele.BasePotential):
    """define the python interface to the c++ InversePower implementation
    """
    cpdef bool periodic 
    def __cinit__(self, pow, eps, radii, ndim=3, boxvec=None, boxl=None):
        assert(ndim == 2 or ndim == 3)
        assert not (boxvec is not None and boxl is not None)
        if boxl is not None:
            boxvec = [boxl] * ndim
        cdef np.ndarray[double, ndim=1] bv
        cdef np.ndarray[double, ndim=1] radiic = np.array(radii, dtype=float) 
        
        if boxvec is None:
            self.periodic = False
            if ndim == 2:
                self.thisptr = shared_ptr[_pele.cBasePotential]( <_pele.cBasePotential*>new 
                                                                 cInversePower[INT2](pow, eps, _pele.Array[double](<double*> radiic.data, radiic.size)) )
            else:
                self.thisptr = shared_ptr[_pele.cBasePotential]( <_pele.cBasePotential*>new 
                                                                 cInversePower[INT3](pow, eps, _pele.Array[double](<double*> radiic.data, radiic.size)) )

        else:
            self.periodic = True
            assert(len(boxvec)==ndim)
            bv = np.array(boxvec, dtype=float)
            if ndim == 2:
                self.thisptr = shared_ptr[_pele.cBasePotential]( <_pele.cBasePotential*>new 
                                                                 cInversePowerPeriodic[INT2](pow, eps, _pele.Array[double](<double*> radiic.data, radiic.size),
                                                                                             _pele.Array[double](<double*> bv.data, bv.size)) )
            else:
                self.thisptr = shared_ptr[_pele.cBasePotential]( <_pele.cBasePotential*>new 
                                                                 cInversePowerPeriodic[INT3](pow, eps, _pele.Array[double](<double*> radiic.data, radiic.size),
                                                                                             _pele.Array[double](<double*> bv.data, bv.size)) )
                