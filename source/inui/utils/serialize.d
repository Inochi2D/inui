/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.utils.serialize;
import fghj;

/**
    Gets whether an Fghj value is empty
*/
bool isEmpty(Fghj value) {
    return value == Fghj.init;
}

/**
    Gets whether an Fghj value is empty
*/
bool isEmpty(FghjNode value) {
    return (value.isLeaf() && value.data == Fghj.init);
}